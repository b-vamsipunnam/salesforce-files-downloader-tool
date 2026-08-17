*** Settings ***
Documentation       Generates the validated Salesforce org_info.json used by download suites without exposing the access token in Robot logs.

Library             ../libraries/CredentialGenerator.py


*** Variables ***
${ORG_ALIAS}         ${EMPTY}
${ORG_INFO_OUTPUT}   ${EXECDIR}${/}org_info.json
${SF_COMMAND}        ${NONE}


*** Tasks ***
Generate Salesforce Authentication File
    [Documentation]    Combines Salesforce org metadata with the dedicated CLI access-token response and atomically writes org_info.json.
    ${message}=    Generate Salesforce Org Info
    ...    ${ORG_ALIAS}
    ...    ${ORG_INFO_OUTPUT}
    ...    ${SF_COMMAND}
    Log To Console    ${message}
