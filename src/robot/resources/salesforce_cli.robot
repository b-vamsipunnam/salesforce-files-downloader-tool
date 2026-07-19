*** Settings ***
Documentation       Validates Salesforce CLI availability and authentication, then loads the target organization context.

Library             OperatingSystem
Library             Collections
Library             Process
Library             json
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
    ${ver_res}=    Run Process    ${sf_cli_path}    --version    stdout=PIPE    stderr=PIPE
    Should Be Equal As Integers    ${ver_res.rc}    0    msg=Salesforce CLI failed to execute.\n${ver_res.stderr}

Load Org Context
    [Documentation]     Runs Salesforce CLI against the supplied organization alias, validates the authentication result, extracts the organization API version, and stores it for suite-level use.
    [Arguments]    ${ORG_ALIAS}
    ${org_res}=    Run Process
    ...    ${sf_cli_path}
    ...    org
    ...    display
    ...    --target-org
    ...    ${ORG_ALIAS}
    ...    --json
    ...    stdout=PIPE
    ...    stderr=PIPE
    Should Be Equal As Integers
    ...    ${org_res.rc}
    ...    0
    ...    msg=Org alias not found or not authenticated: ${ORG_ALIAS}\n${org_res.stderr}
    ${json_obj}=    Safe Parse Sf Json    ${org_res.stdout}
    Dictionary Should Contain Key    ${json_obj}    result
    ${result_dict}=    Get From Dictionary    ${json_obj}    result
    Dictionary Should Contain Key    ${result_dict}    apiVersion
    ${cli_api_version}=    Get From Dictionary    ${result_dict}    apiVersion
    Set Suite Variable    ${CLI_API_VERSION}    ${cli_api_version}
    Log To Console    Connected to ${ORG_ALIAS} (API v${CLI_API_VERSION})

Safe Parse Sf Json
    [Documentation]     Extracts and parses the first JSON object or array from Salesforce CLI output. Supports output containing leading warnings or banners and fails when no JSON content is found.
    [Arguments]    ${raw_output}
    ${obj_start}=    Evaluate    $raw_output.find('{')
    ${arr_start}=    Evaluate    $raw_output.find('[')
    ${start}=    Set Variable    ${obj_start}
    IF    ${start} == -1
        ${start}=    Set Variable    ${arr_start}
    END
    IF    ${start} == -1
        Log To Console    No JSON found in output:\n${raw_output}
        Fail    Invalid sf CLI output - no JSON block
    END
    ${json_text}=    Evaluate    $raw_output[$start:]
    ${data}=    Evaluate    json.loads($json_text)    modules=json
    RETURN    ${data}
