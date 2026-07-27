*** Settings ***
Documentation       Validates Salesforce CLI availability and authentication, then loads the target organization context.

Library             OperatingSystem
Library             Collections
Library             Process
Library             json
Library             pabot.PabotLib
Library             ../libraries/SalesforceSupport.py
Resource            configuration.robot


*** Keywords ***
Check Prerequisites
    [Documentation]     Verifies that Salesforce CLI is available and executable, then confirms that the supplied organization alias is authenticated and accessible.
    [Arguments]    ${ORG_ALIAS}
    Resolve Salesforce CLI
    Validate Salesforce CLI
    Load Org Context    ${ORG_ALIAS}

Resolve Salesforce CLI
    [Documentation]     Locates the Salesforce CLI executable on the system PATH, stores its resolved path as a suite variable, and fails with a clear message when the executable is unavailable.
    ${sf_path}=    Evaluate    shutil.which("sf")    modules=shutil
    Should Not Be Equal
    ...    ${sf_path}
    ...    ${NONE}
    ...    msg=Salesforce CLI (sf) not found in PATH.
    Set Suite Variable    ${sf_cli_path}    ${sf_path}
    Log To Console    Using SF CLI: ${sf_cli_path}

Validate Salesforce CLI
    [Documentation]     Executes the Salesforce CLI version command and verifies that the resolved executable runs successfully.
    ${ver_res}=    Run Process    ${sf_cli_path}    --version
    Should Be Equal As Integers    ${ver_res.rc}    0    msg=Salesforce CLI failed to execute.\n${ver_res.stderr}

Load Org Context
    [Documentation]     Runs Salesforce CLI against the supplied organization alias, validates the authentication result, extracts the organization API version, and stores it for suite-level use.
    [Arguments]    ${ORG_ALIAS}
    ${previous_level}=    Set Log Level    NONE
    TRY
        ${org_res}=    Run Process
        ...    ${sf_cli_path}
        ...    org
        ...    display
        ...    --target-org
        ...    ${ORG_ALIAS}
        ...    --json
        Should Be Equal As Integers
        ...    ${org_res.rc}
        ...    0
        ...    msg=Org alias not found or not authenticated: ${ORG_ALIAS}\n${org_res.stderr}
        ${json_obj}=    Safe Parse Sf Json    ${org_res.stdout}
        Dictionary Should Contain Key    ${json_obj}    result
        ${result_dict}=    Get From Dictionary    ${json_obj}    result
        Dictionary Should Contain Key    ${result_dict}    apiVersion
        Dictionary Should Contain Key    ${result_dict}    id
        ${cli_api_version}=    Get From Dictionary
        ...    ${result_dict}
        ...    apiVersion
        ${cli_org_id}=    Get From Dictionary    ${result_dict}    id
    FINALLY
        Set Log Level    ${previous_level}
    END
    Set Suite Variable    ${CLI_API_VERSION}    ${cli_api_version}
    Set Suite Variable    ${CLI_ORG_ID}    ${cli_org_id}
    Set Suite Variable    ${SF_ORG_ALIAS}    ${ORG_ALIAS}
    Log To Console
    ...    Connected to ${SF_ORG_ALIAS} (API v${CLI_API_VERSION})

Initialize Salesforce CLI Context From Org Info
    [Documentation]     Loads the authenticated alias, org ID, and API version directly from org_info.json and resolves the CLI path without running an org display command.
    ${current_sf_path}=    Get Variable Value
    ...    \${sf_cli_path}
    ...    ${NONE}
    ${current_org_alias}=    Get Variable Value
    ...    \${SF_ORG_ALIAS}
    ...    ${NONE}
    ${current_org_id}=    Get Variable Value
    ...    \${CLI_ORG_ID}
    ...    ${NONE}
    ${previous_level}=    Set Log Level    NONE
    TRY
        ${json_text}=    OperatingSystem.Get File
        ...    ${ORG_INFO_FILE}
        ...    encoding=UTF-8-sig
        ${org_dict}=    Evaluate    json.loads($json_text)    modules=json
        Dictionary Should Contain Key
        ...    ${org_dict}
        ...    result
        ...    msg=${ORG_INFO_FILE} does not contain a result field.
        ${result}=    Get From Dictionary    ${org_dict}    result
        Dictionary Should Contain Key
        ...    ${result}
        ...    alias
        ...    msg=${ORG_INFO_FILE} does not contain an authenticated org alias.
        Dictionary Should Contain Key
        ...    ${result}
        ...    id
        ...    msg=${ORG_INFO_FILE} does not contain an authenticated org ID.
        Dictionary Should Contain Key
        ...    ${result}
        ...    apiVersion
        ...    msg=${ORG_INFO_FILE} does not contain a Salesforce API version.
        ${org_alias}=    Get From Dictionary    ${result}    alias
        ${org_info_id}=    Get From Dictionary    ${result}    id
        ${org_info_api_version}=    Get From Dictionary
        ...    ${result}
        ...    apiVersion
    FINALLY
        Set Log Level    ${previous_level}
    END
    IF    $current_sf_path is not None and $current_org_alias is not None and $current_org_id is not None
        Should Be Equal
        ...    ${current_org_id}
        ...    ${org_info_id}
        ...    msg=The loaded Salesforce CLI context does not match ${ORG_INFO_FILE}. Regenerate the authentication file from the intended org.
        RETURN
    END
    Resolve Salesforce CLI
    Set Suite Variable    ${SF_ORG_ALIAS}    ${org_alias}
    Set Suite Variable    ${CLI_ORG_ID}    ${org_info_id}
    Set Suite Variable    ${CLI_API_VERSION}    ${org_info_api_version}
    Log To Console
    ...    Connected to ${SF_ORG_ALIAS} (API v${CLI_API_VERSION})

Get Salesforce Daily API Limits
    [Documentation]     Retrieves DailyApiRequests through a locked Salesforce CLI command and retries bounded transient failures such as nonzero exit codes, empty output, invalid JSON, or a missing limit.
    [Arguments]    ${process_keyword}=Run Process
    ${max_attempts}=    Convert To Integer
    ...    ${API_LIMIT_LOOKUP_MAX_ATTEMPTS}
    Should Be True
    ...    ${max_attempts} > 0
    ...    msg=API_LIMIT_LOOKUP_MAX_ATTEMPTS must be greater than zero.
    ${last_error}=    Set Variable
    ...    Salesforce CLI limits lookup did not run.
    ${range_end}=    Evaluate    $max_attempts + 1

    FOR    ${attempt}    IN RANGE    1    ${range_end}
        pabot.PabotLib.Acquire Lock    salesforce_cli_lock
        TRY
            ${limits_res}=    Run Keyword
            ...    ${process_keyword}
            ...    ${sf_cli_path}
            ...    org
            ...    list
            ...    limits
            ...    --target-org
            ...    ${SF_ORG_ALIAS}
            ...    --json
        FINALLY
            pabot.PabotLib.Release Lock    salesforce_cli_lock
        END

        IF    ${limits_res.rc} != 0
            ${last_error}=    Set Variable
            ...    Salesforce CLI exited with code ${limits_res.rc}: ${limits_res.stderr}
            Log Salesforce Limit Lookup Retry
            ...    ${attempt}
            ...    ${max_attempts}
            ...    ${last_error}
            IF    ${attempt} < ${max_attempts}    CONTINUE
            BREAK
        END

        ${stdout}=    Evaluate    str($limits_res.stdout).strip()
        IF    not $stdout
            ${last_error}=    Set Variable
            ...    Salesforce CLI returned empty output with exit code 0.
            Log Salesforce Limit Lookup Retry
            ...    ${attempt}
            ...    ${max_attempts}
            ...    ${last_error}
            IF    ${attempt} < ${max_attempts}    CONTINUE
            BREAK
        END

        ${parsed}    ${limits_json}=    Try Parse First Json Value
        ...    ${stdout}
        IF    not ${parsed}
            ${last_error}=    Set Variable
            ...    Salesforce CLI returned invalid JSON with exit code 0.
            Log Salesforce Limit Lookup Retry
            ...    ${attempt}
            ...    ${max_attempts}
            ...    ${last_error}
            IF    ${attempt} < ${max_attempts}    CONTINUE
            BREAK
        END

        ${has_result}=    Evaluate
        ...    isinstance($limits_json, dict) and isinstance($limits_json.get("result"), list)
        IF    not ${has_result}
            ${last_error}=    Set Variable
            ...    Salesforce CLI limits response did not contain a result list.
            Log Salesforce Limit Lookup Retry
            ...    ${attempt}
            ...    ${max_attempts}
            ...    ${last_error}
            IF    ${attempt} < ${max_attempts}    CONTINUE
            BREAK
        END

        ${limits}=    Get From Dictionary    ${limits_json}    result
        ${daily_limit}=    Set Variable    ${NONE}
        FOR    ${limit}    IN    @{limits}
            ${is_daily_limit}=    Evaluate
            ...    isinstance($limit, dict) and $limit.get("name") == "DailyApiRequests"
            IF    ${is_daily_limit}
                ${daily_limit}=    Set Variable    ${limit}
                BREAK
            END
        END
        IF    $daily_limit is None
            ${last_error}=    Set Variable
            ...    DailyApiRequests was not present in the Salesforce CLI response.
            Log Salesforce Limit Lookup Retry
            ...    ${attempt}
            ...    ${max_attempts}
            ...    ${last_error}
            IF    ${attempt} < ${max_attempts}    CONTINUE
            BREAK
        END

        ${maximum}=    Get From Dictionary    ${daily_limit}    max
        ${remaining}=    Get From Dictionary    ${daily_limit}    remaining
        ${maximum}=    Convert To Integer    ${maximum}
        ${remaining}=    Convert To Integer    ${remaining}
        RETURN    ${maximum}    ${remaining}
    END

    Fail
    ...    Unable to retrieve Salesforce DailyApiRequests after ${max_attempts} attempts. Last error: ${last_error}

Log Salesforce Limit Lookup Retry
    [Documentation]     Logs a sanitized warning for a failed limits lookup attempt and waits before another attempt when retries remain.
    [Arguments]    ${attempt}    ${max_attempts}    ${reason}
    IF    ${attempt} < ${max_attempts}
        Log
        ...    Salesforce API limit lookup attempt ${attempt} failed: ${reason} Retrying.
        ...    level=WARN
        Sleep    ${API_LIMIT_LOOKUP_RETRY_DELAY}
    ELSE
        Log
        ...    Salesforce API limit lookup attempt ${attempt} failed: ${reason}
        ...    level=WARN
    END

Estimate Metadata API Requests
    [Documentation]     Estimates REST requests for batched ContentDocument and optional ContentDocumentLink metadata retrieval.
    [Arguments]
    ...    ${content_id_count}
    ...    ${generate_content_document_link_file}
    ${content_id_count}=    Convert To Integer    ${content_id_count}
    ${batch_size}=    Convert To Integer    ${METADATA_BATCH_SIZE}
    Should Be True
    ...    ${content_id_count} >= 0
    ...    msg=ContentDocument ID count cannot be negative.
    Should Be True
    ...    ${batch_size} > 0
    ...    msg=METADATA_BATCH_SIZE must be greater than zero.
    ${metadata_batches}=    Evaluate
    ...    math.ceil($content_id_count / $batch_size)
    ...    modules=math
    ${queries_per_batch}=    Convert To Integer    1
    IF    '${generate_content_document_link_file.lower()}' == 'yes'
        ${queries_per_batch}=    Convert To Integer    2
    END
    ${estimated_metadata_requests}=    Evaluate
    ...    $metadata_batches * $queries_per_batch
    RETURN    ${metadata_batches}    ${estimated_metadata_requests}

Check Salesforce API Capacity
    [Documentation]     Stops before artifact creation when estimated metadata requests, the safety buffer, and the required reserve exceed the org's remaining DailyApiRequests allocation.
    [Arguments]
    ...    ${content_id_count}
    ...    ${generate_content_document_link_file}
    IF    not ${ENABLE_API_CAPACITY_CHECK}
        Log To Console
        ...    Salesforce API capacity check is disabled.
        RETURN
    END

    Initialize Salesforce CLI Context From Org Info
    ${daily_max}    ${daily_remaining}=    Get Salesforce Daily API Limits
    ${metadata_batches}    ${estimated_metadata_requests}=
    ...    Estimate Metadata API Requests
    ...    ${content_id_count}
    ...    ${generate_content_document_link_file}
    ${safety_buffer}=    Convert To Integer    ${API_REQUEST_SAFETY_BUFFER}
    ${minimum_remaining}=    Convert To Integer
    ...    ${MINIMUM_API_REQUESTS_REMAINING}
    Should Be True
    ...    ${safety_buffer} >= 0
    ...    msg=API_REQUEST_SAFETY_BUFFER cannot be negative.
    Should Be True
    ...    ${minimum_remaining} >= 0
    ...    msg=MINIMUM_API_REQUESTS_REMAINING cannot be negative.
    ${capacity_check_requests}=    Convert To Integer    1
    ${estimated_tool_requests}=    Evaluate
    ...    $estimated_metadata_requests + $capacity_check_requests
    ${projected_remaining}=    Evaluate
    ...    $daily_remaining - $estimated_tool_requests

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
    Log To Console    API Capacity Check Requests: ${capacity_check_requests}
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
    Log To Console
    ...    Salesforce API capacity check: PASSED

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

Safe Parse Sf Json
    [Documentation]     Parses the first valid JSON object or array from Salesforce CLI output without logging the raw output.
    [Arguments]    ${raw_output}
    TRY
        ${data}=    Parse First Json Value
        ...    ${raw_output}
    EXCEPT
        Log To Console
        ...    Unable to parse Salesforce CLI JSON output.
        Fail    Invalid sf CLI JSON output
    END
    RETURN    ${data}
