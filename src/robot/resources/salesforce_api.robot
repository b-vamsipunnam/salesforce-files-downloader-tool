*** Settings ***
Documentation       Handles Salesforce authentication, REST requests, SOQL execution, pagination, ID validation, and metadata retrieval.

Library             OperatingSystem
Library             Collections
Library             String
Library             RequestsLibrary
Library             json
Library             urllib.parse
Resource            configuration.robot


*** Keywords ***
Initialize Salesforce Session
    [Documentation]     Reads Salesforce authentication information from the configured org_info.json file, creates a uniquely named RequestsLibrary session with Bearer authentication, stores the API version for the current test, and returns the session alias.
    [Tags]    robot:flatten
    ${previous_level}=    Set Log Level    NONE
    TRY
        ${uuid}=    Evaluate    __import__('uuid').uuid4().hex
        ${session_alias}=    Set Variable    salesforce_${uuid}
        Set Test Variable    ${session_alias}
        ${json_text}=    OperatingSystem.Get File
        ...    ${ORG_INFO_FILE}
        ...    encoding=UTF-8-sig
        ${org_dict}=    Evaluate    json.loads($json_text)    modules=json
        Validate Salesforce Org Info    ${org_dict}
        ${token}=    Set Variable    ${org_dict['result']['accessToken']}
        ${instance}=    Set Variable    ${org_dict['result']['instanceUrl']}
        ${api_version}=    Set Variable    ${org_dict['result']['apiVersion']}
        ${org_alias}=    Set Variable    ${org_dict['result']['alias']}
        Set Test Variable    ${api_version}
        Set Test Variable    ${SF_ORG_ALIAS}    ${org_alias}
        ${headers}=    Create Dictionary
        ...    Authorization=Bearer ${token}
        ...    Content-Type=application/json
        Create Session
        ...    ${session_alias}
        ...    ${instance}
        ...    headers=${headers}
        ...    verify=${TRUE}
    FINALLY
        Set Log Level    ${previous_level}
    END
    RETURN    ${session_alias}

Validate Salesforce Org Info
    [Documentation]     Fails with a safe, actionable message when org_info.json is unsuccessful, incomplete, or contains the redacted placeholder returned by newer Salesforce CLI versions. The access token is never included in the failure message.
    [Arguments]    ${org_dict}
    ${status}=    Get From Dictionary    ${org_dict}    status    default=${NONE}
    ${result}=    Get From Dictionary    ${org_dict}    result    default=${NONE}
    ${valid_status}=    Evaluate    str($status) == '0'
    ${valid_result}=    Evaluate    hasattr($result, 'get')
    IF    not $valid_status or not $valid_result
        Fail    Invalid org_info.json: Salesforce CLI did not return a successful org result. Regenerate it with the Robot authentication command documented in docs/Authentication.md.
    END
    ${token}=    Get From Dictionary    ${result}    accessToken    default=${NONE}
    ${instance}=    Get From Dictionary    ${result}    instanceUrl    default=${NONE}
    ${api}=    Get From Dictionary    ${result}    apiVersion    default=${NONE}
    ${alias}=    Get From Dictionary    ${result}    alias    default=${NONE}
    ${usable_token}=    Evaluate
    ...    isinstance($token, str) and bool($token.strip()) and not $token.lstrip().startswith('[REDACTED]')
    ${usable_context}=    Evaluate
    ...    isinstance($instance, str) and bool($instance.strip()) and isinstance($api, str) and bool($api.strip()) and isinstance($alias, str) and bool($alias.strip())
    IF    not $usable_token
        Fail    Invalid org_info.json: accessToken is empty or redacted. Run the Robot authentication command documented in docs/Authentication.md; sf org display output is intentionally redacted.
    END
    IF    not $usable_context
        Fail    Invalid org_info.json: alias, instanceUrl, or apiVersion is missing. Regenerate it with the Robot authentication command documented in docs/Authentication.md.
    END

Get Salesforce Login Info
    [Documentation]     Reads the Salesforce instance URL and access token from org_info.json, determines the organization domain, constructs the authenticated frontdoor login URL, and returns the URL for browser initialization.
    [Tags]    robot:flatten
    ${previous_level}=    Set Log Level    NONE
    TRY
        ${json_text}=    OperatingSystem.Get File
        ...    ${ORG_INFO_FILE}
        ...    encoding=UTF-8-sig
        ${org_dict}=    Evaluate    json.loads($json_text)    modules=json
        ${instance_url}=    Set Variable
        ...    ${org_dict['result']['instanceUrl']}
        ${access_token}=    Set Variable
        ...    ${org_dict['result']['accessToken']}
        ${parsed}=    Evaluate
        ...    urllib.parse.urlparse($instance_url)
        ...    modules=urllib.parse
        ${netloc}=    Set Variable    ${parsed.netloc}
        ${org_domain}=    Replace String
        ...    ${netloc}
        ...    .my.salesforce.com
        ...    ${EMPTY}
        ${login_url}=    Catenate
        ...    SEPARATOR=${EMPTY}
        ...    ${instance_url}/secur/frontdoor.jsp?sid=${access_token}
        Set Test Variable    ${org_domain}
    FINALLY
        Set Log Level    ${previous_level}
    END
    RETURN    ${login_url}

Send Safe Salesforce GET Request
    [Documentation]     Sends a GET request through the supplied Salesforce REST session while suppressing sensitive request logging. Returns the response for HTTP 200 or returns None after logging a sanitized warning for request and HTTP failures.
    [Arguments]    ${session_alias}    ${url}    ${params}=${NONE}
    ${previous_level}=    Set Log Level    NONE
    TRY
        ${status}    ${resp}=    Run Keyword And Ignore Error
        ...    GET On Session
        ...    ${session_alias}
        ...    ${url}
        ...    params=${params}
        ...    expected_status=anything
    FINALLY
        Set Log Level    ${previous_level}
    END
    IF    '${status}' == 'FAIL'
        ${safe_error}=    Redact Sensitive Text    ${resp}
        Log    Salesforce GET failed for ${url}: ${safe_error}    level=WARN
        RETURN    ${NONE}
    END
    ${status_code}=    Set Variable    ${resp.status_code}
    IF    ${status_code} != 200
        ${body}=    Set Variable    ${resp.text}
        ${auth_expired}=    Is Salesforce Auth Failure    ${status_code}    ${body}
        IF    ${auth_expired}
            Fail    AUTH_SESSION_EXPIRED: Salesforce REST session is no longer valid.
        END
        ${body_preview}=    Redact Sensitive Text    ${body}
        ${body_preview}=    Evaluate    str($body_preview)[:500]
        Log
        ...    Salesforce GET returned HTTP ${status_code}: ${body_preview}
        ...    level=WARN
        RETURN    ${NONE}
    END
    RETURN    ${resp}

Get Salesforce Daily API Limits Via REST
    [Documentation]     Retrieves DailyApiRequests directly from the authenticated Salesforce REST limits endpoint and returns its maximum and remaining values. This avoids starting a Salesforce CLI subprocess inside parallel Robot workers.
    [Arguments]
    ...    ${session_alias}
    ...    ${request_keyword}=Send Safe Salesforce GET Request
    ${url}=    Set Variable    /services/data/v${api_version}/limits
    ${resp}=    Run Keyword
    ...    ${request_keyword}
    ...    ${session_alias}
    ...    ${url}
    IF    $resp is None
        Fail    Salesforce REST limits request failed.
    END
    ${payload}=    Evaluate    $resp.json()
    ${daily_limit}=    Get From Dictionary
    ...    ${payload}
    ...    DailyApiRequests
    ...    default=${NONE}
    IF    $daily_limit is None
        Fail    DailyApiRequests was not present in the Salesforce REST limits response.
    END
    ${maximum}=    Get From Dictionary    ${daily_limit}    Max
    ${remaining}=    Get From Dictionary    ${daily_limit}    Remaining
    ${maximum}=    Convert To Integer    ${maximum}
    ${remaining}=    Convert To Integer    ${remaining}
    RETURN    ${maximum}    ${remaining}

Estimate Metadata API Requests
    [Documentation]     Estimates REST requests for batched ContentDocument and optional ContentDocumentLink metadata retrieval.
    [Arguments]    ${content_id_count}    ${generate_content_document_link_file}
    ${content_id_count}=    Convert To Integer    ${content_id_count}
    ${batch_size}=    Convert To Integer    ${METADATA_BATCH_SIZE}
    Should Be True    ${content_id_count} >= 0    msg=ContentDocument ID count cannot be negative.
    Should Be True    ${batch_size} > 0    msg=METADATA_BATCH_SIZE must be greater than zero.
    ${metadata_batches}=    Evaluate    math.ceil($content_id_count / $batch_size)    modules=math
    ${queries_per_batch}=    Convert To Integer    1
    IF    '${generate_content_document_link_file.lower()}' == 'yes'
        ${queries_per_batch}=    Convert To Integer    2
    END
    ${estimated_metadata_requests}=    Evaluate    $metadata_batches * $queries_per_batch
    RETURN    ${metadata_batches}    ${estimated_metadata_requests}

Check Salesforce API Capacity
    [Documentation]     Reads DailyApiRequests through the authenticated REST session and stops before migration workbook creation when estimated metadata requests, the safety buffer, and the required reserve exceed the remaining allocation.
    [Arguments]
    ...    ${content_id_count}
    ...    ${generate_content_document_link_file}
    ...    ${session_alias}=${NONE}
    ...    ${limits_keyword}=Get Salesforce Daily API Limits Via REST
    IF    not ${ENABLE_API_CAPACITY_CHECK}
        Log To Console    Salesforce API capacity check is disabled.
        RETURN
    END
    IF    $session_alias is None
        Fail    Salesforce REST session is required for the API capacity check.
    END
    ${daily_max}    ${daily_remaining}=    Run Keyword    ${limits_keyword}    ${session_alias}
    ${daily_max}=    Convert To Integer    ${daily_max}
    ${daily_remaining}=    Convert To Integer    ${daily_remaining}
    ${metadata_batches}    ${estimated_metadata_requests}=
    ...    Estimate Metadata API Requests
    ...    ${content_id_count}
    ...    ${generate_content_document_link_file}
    ${safety_buffer}=    Convert To Integer    ${API_REQUEST_SAFETY_BUFFER}
    ${minimum_remaining}=    Convert To Integer    ${MINIMUM_API_REQUESTS_REMAINING}
    Should Be True    ${safety_buffer} >= 0    msg=API_REQUEST_SAFETY_BUFFER cannot be negative.
    Should Be True    ${minimum_remaining} >= 0    msg=MINIMUM_API_REQUESTS_REMAINING cannot be negative.
    ${estimated_tool_requests}=    Evaluate    $estimated_metadata_requests + 1
    ${projected_remaining}=    Evaluate    $daily_remaining - $estimated_tool_requests

    Log To Console    \n==================================================
    Log To Console    Salesforce API Capacity Check
    Log To Console    --------------------------------------------------
    Log To Console    Org Alias: ${SF_ORG_ALIAS}
    Log To Console    Daily API Maximum: ${daily_max}
    Log To Console    Daily API Remaining: ${daily_remaining}
    Log To Console    ContentDocument IDs: ${content_id_count}
    Log To Console    Metadata Batch Size: ${METADATA_BATCH_SIZE}
    Log To Console    Metadata Batches: ${metadata_batches}
    Log To Console
    ...    Minimum Estimated Metadata Requests: ${estimated_metadata_requests} (additional pagination requests are covered only by the safety buffer)
    Log To Console    API Capacity Check Requests: 1
    Log To Console    Estimated Tool Requests: ${estimated_tool_requests}
    Log To Console    Safety Buffer: ${safety_buffer}
    Log To Console    Minimum Remaining Reserve: ${minimum_remaining}
    Log To Console    Projected API Requests Remaining: ${projected_remaining}
    Log To Console    ==================================================

    Validate Salesforce API Capacity
    ...    ${daily_remaining}
    ...    ${estimated_tool_requests}
    ...    ${safety_buffer}
    ...    ${minimum_remaining}
    Log To Console    Salesforce API capacity check: PASSED

Validate Salesforce API Capacity
    [Documentation]     Fails when remaining API capacity cannot cover estimated tool requests, the safety buffer, and the required post-run reserve.
    [Arguments]
    ...    ${daily_remaining}
    ...    ${estimated_tool_requests}
    ...    ${safety_buffer}
    ...    ${minimum_remaining}
    ${required_capacity}=    Evaluate
    ...    int($estimated_tool_requests) + int($safety_buffer) + int($minimum_remaining)
    IF    int($daily_remaining) < ${required_capacity}
        Fail
        ...    Insufficient Salesforce API capacity. Remaining: ${daily_remaining}; estimated tool requests: ${estimated_tool_requests}; safety buffer: ${safety_buffer}; required reserve: ${minimum_remaining}. Reduce the input size or run again after API capacity becomes available.
    END

Execute SOQL Query
    [Documentation]     Executes a SOQL query through the active Salesforce REST session and follows nextRecordsUrl pagination until all records are retrieved. Fails when a request is unsuccessful, pagination data is incomplete, or the pagination safety limit is exceeded.
    [Arguments]
    ...    ${soql}
    ...    ${session_alias}
    ...    ${request_keyword}=Send Safe Salesforce GET Request
    ${all_records}=    Create List
    ${empty_records}=    Create List
    ${params}=    Create Dictionary    q=${soql}
    ${url}=    Set Variable    /services/data/v${api_version}/query
    ${page_number}=    Set Variable    1
    WHILE    ${TRUE}
        ${resp}=    Run Keyword
        ...    ${request_keyword}
        ...    ${session_alias}
        ...    ${url}
        ...    params=${params}
        IF    $resp is None
            Fail    Salesforce SOQL query failed while retrieving page ${page_number}.
        END
        ${payload}=    Evaluate    $resp.json()
        ${records}=    Get From Dictionary    ${payload}    records    default=${empty_records}
        ${all_records}=    Combine Lists    ${all_records}    ${records}
        ${done}=    Get From Dictionary    ${payload}    done    default=${TRUE}
        IF    ${done}    BREAK
        ${next_url}=    Get From Dictionary    ${payload}    nextRecordsUrl    default=${NONE}
        IF    $next_url is None
            Fail    Salesforce returned done=false without nextRecordsUrl on page ${page_number}.
        END
        ${url}=    Set Variable    ${next_url}
        ${params}=    Set Variable    ${NONE}
        ${page_number}=    Evaluate    ${page_number} + 1
        IF    ${page_number} > 10000
            Fail    Salesforce SOQL pagination exceeded the safety limit of 10,000 pages.
        END
    END
    RETURN    ${all_records}

Is Valid ContentDocument ID
    [Documentation]     Returns True when the supplied value is a 15-character or 18-character alphanumeric Salesforce ID beginning with the ContentDocument prefix 069. Otherwise, returns False.
    [Arguments]    ${content_id}
    ${is_valid}=    Evaluate
    ...    re.fullmatch(r'069[A-Za-z0-9]{12}(?:[A-Za-z0-9]{3})?', str($content_id)) is not None
    ...    modules=re
    RETURN    ${is_valid}

Get ContentDocument Metadata Map
    [Documentation]     Retrieves ContentDocument metadata for the supplied valid IDs using configurable SOQL batches. Returns a dictionary keyed by ContentDocument ID containing file title, extension, description, latest version ID, and expected content size.
    [Arguments]
    ...    ${content_ids}
    ...    ${batch_size}=200
    ...    ${query_keyword}=Execute SOQL Query
    ${content_doc_map}=    Create Dictionary
    @{valid_ids}=    Create List
    FOR    ${content_id}    IN    @{content_ids}
        ${content_id}=    Strip String    ${content_id}
        ${is_valid}=    Is Valid ContentDocument ID    ${content_id}
        IF    ${is_valid}    Append To List    ${valid_ids}    ${content_id}
    END
    @{id_batches}=    Split List Into Batches    ${valid_ids}    ${batch_size}
    FOR    ${batch}    IN    @{id_batches}
        ${quoted_ids}=    Format IDs For SOQL IN Clause    ${batch}
        ${soql}=    Set Variable
        ...    SELECT Id, Description, Title, FileExtension, LatestPublishedVersionId, ContentSize FROM ContentDocument WHERE Id IN (${quoted_ids})
        ${records}=    Run Keyword
        ...    ${query_keyword}
        ...    ${soql}
        ...    ${session_alias}
        FOR    ${record}    IN    @{records}
            ${doc_id}=    Get From Dictionary    ${record}    Id
            Set To Dictionary    ${content_doc_map}    ${doc_id}=${record}
        END
    END
    RETURN    ${content_doc_map}

Get ContentDocumentLink Metadata Map
    [Documentation]     Retrieves all ContentDocumentLink records associated with the supplied valid ContentDocument IDs using configurable SOQL batches. Returns a dictionary keyed by ContentDocument ID, with each value containing a list of all related link records.
    [Arguments]
    ...    ${content_ids}
    ...    ${batch_size}=200
    ...    ${query_keyword}=Execute SOQL Query
    ${cdl_map}=    Create Dictionary
    @{valid_ids}=    Create List
    FOR    ${content_id}    IN    @{content_ids}
        ${content_id}=    Strip String    ${content_id}
        ${is_valid}=    Is Valid ContentDocument ID    ${content_id}
        IF    ${is_valid}    Append To List    ${valid_ids}    ${content_id}
    END
    @{id_batches}=    Split List Into Batches    ${valid_ids}    ${batch_size}
    FOR    ${batch}    IN    @{id_batches}
        ${quoted_ids}=    Format IDs For SOQL IN Clause    ${batch}
        ${soql}=    Set Variable
        ...    SELECT ContentDocumentId, Id, ShareType, Visibility, LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId IN (${quoted_ids})
        ${records}=    Run Keyword
        ...    ${query_keyword}
        ...    ${soql}
        ...    ${session_alias}
        FOR    ${record}    IN    @{records}
            ${doc_id}=    Get From Dictionary    ${record}    ContentDocumentId
            ${links}=    Get From Dictionary
            ...    ${cdl_map}
            ...    ${doc_id}
            ...    default=${NONE}
            IF    $links is None
                ${links}=    Create List
                Set To Dictionary    ${cdl_map}    ${doc_id}=${links}
            END
            Append To List    ${links}    ${record}
        END
    END
    RETURN    ${cdl_map}

Split List Into Batches
    [Documentation]     Splits the supplied list into smaller lists containing no more than the requested number of items and returns the resulting list of batches.
    [Arguments]    ${items}    ${batch_size}
    @{batches}=    Create List
    ${total}=    Get Length    ${items}
    FOR    ${start}    IN RANGE    0    ${total}    ${batch_size}
        ${end}=    Evaluate    min(${start} + ${batch_size}, ${total})
        ${batch}=    Get Slice From List    ${items}    ${start}    ${end}
        Append To List    ${batches}    ${batch}
    END
    RETURN    ${batches}

Format IDs For SOQL IN Clause
    [Documentation]     Wraps each supplied Salesforce ID in single quotes and joins the values with commas for use inside a SOQL IN clause.
    [Arguments]    ${ids}
    @{quoted_ids}=    Create List
    FOR    ${id}    IN    @{ids}
        ${quoted_id}=    Catenate    SEPARATOR=${EMPTY}    '    ${id}    '
        Append To List    ${quoted_ids}    ${quoted_id}
    END
    ${joined_ids}=    Catenate    SEPARATOR=,    @{quoted_ids}
    RETURN    ${joined_ids}
