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
    ${uuid}=    Evaluate    __import__('uuid').uuid4().hex
    ${session_alias}=    Set Variable    salesforce_${uuid}
    Set Test Variable    ${session_alias}
    ${json_text}=    OperatingSystem.Get File    ${ORG_INFO_FILE}    encoding=UTF-8-sig
    ${org_dict}=    Evaluate    json.loads($json_text)    modules=json
    ${token}=    Set Variable    ${org_dict['result']['accessToken']}
    ${instance}=    Set Variable    ${org_dict['result']['instanceUrl']}
    ${api_version}=    Set Variable    ${org_dict['result']['apiVersion']}
    ${org_alias}=    Set Variable    ${org_dict['result']['alias']}
    Set Test Variable    ${api_version}
    ${headers}=    Create Dictionary
    ...    Authorization=Bearer ${token}
    ...    Content-Type=application/json
    Create Session
    ...    ${session_alias}
    ...    ${instance}
    ...    headers=${headers}
    ...    verify=${TRUE}
    RETURN    ${session_alias}

Get Salesforce Login Info
    [Documentation]     Reads the Salesforce instance URL and access token from org_info.json, determines the organization domain, constructs the authenticated frontdoor login URL, and returns the URL for browser initialization.
    [Tags]    robot:flatten
    ${json_text}=    OperatingSystem.Get File    ${ORG_INFO_FILE}    encoding=UTF-8-sig
    ${org_dict}=    Evaluate    json.loads($json_text)    modules=json
    ${instance_url}=    Set Variable    ${org_dict['result']['instanceUrl']}
    ${access_token}=    Set Variable    ${org_dict['result']['accessToken']}
    ${parsed}=    Evaluate    urllib.parse.urlparse($instance_url)    modules=urllib.parse
    ${netloc}=    Set Variable    ${parsed.netloc}
    ${org_domain}=    Replace String    ${netloc}    .my.salesforce.com    ${EMPTY}
    ${login_url}=    Catenate    SEPARATOR=    ${instance_url}/secur/frontdoor.jsp?sid=${access_token}
    Set Test Variable    ${org_domain}
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
    FINALLY
        Set Log Level    ${previous_level}
    END
    IF    '${status}' == 'FAIL'
        Log    Salesforce GET failed for ${url}: ${resp}    level=WARN
        RETURN    ${NONE}
    END
    ${status_code}=    Set Variable    ${resp.status_code}
    IF    ${status_code} != 200
        ${body}=    Set Variable    ${resp.text}
        ${body_preview}=    Evaluate    str($body)[:500]
        Log
        ...    Salesforce GET returned HTTP ${status_code}: ${body_preview}
        ...    level=WARN
        RETURN    ${NONE}
    END
    RETURN    ${resp}

Execute SOQL Query
    [Documentation]     Executes a SOQL query through the active Salesforce REST session and follows nextRecordsUrl pagination until all records are retrieved. Fails when a request is unsuccessful, pagination data is incomplete, or the pagination safety limit is exceeded.
    [Arguments]    ${soql}    ${session_alias}
    ${all_records}=    Create List
    ${empty_records}=    Create List
    ${params}=    Create Dictionary    q=${soql}
    ${url}=    Set Variable    /services/data/v${api_version}/query
    ${page_number}=    Set Variable    1
    WHILE    ${TRUE}
        ${resp}=    Send Safe Salesforce GET Request
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
    [Arguments]    ${content_ids}    ${batch_size}=200
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
        ${records}=    Execute SOQL Query    ${soql}    ${session_alias}
        FOR    ${record}    IN    @{records}
            ${doc_id}=    Get From Dictionary    ${record}    Id
            Set To Dictionary    ${content_doc_map}    ${doc_id}=${record}
        END
    END
    RETURN    ${content_doc_map}

Get ContentDocumentLink Metadata Map
    [Documentation]     Retrieves all ContentDocumentLink records associated with the supplied valid ContentDocument IDs using configurable SOQL batches. Returns a dictionary keyed by ContentDocument ID, with each value containing a list of all related link records.
    [Arguments]    ${content_ids}    ${batch_size}=200
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
        ${records}=    Execute SOQL Query    ${soql}    ${session_alias}
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
        ${quoted_id}=    Catenate    SEPARATOR=    '    ${id}    '
        Append To List    ${quoted_ids}    ${quoted_id}
    END
    ${joined_ids}=    Catenate    SEPARATOR=,    @{quoted_ids}
    RETURN    ${joined_ids}
