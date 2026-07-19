*** Settings ***
Documentation       Performs suite-level cleanup by closing browser sessions and removing temporary runtime artifacts.

Library             SeleniumLibrary
Library             OperatingSystem
Resource            configuration.robot


*** Keywords ***
Cleanup Runtime Artifacts
    [Documentation]     Removes recognized temporary files and UUID-named temporary files from the execution directory.
    ${items}=    List Directory    ${EXECDIR}
    FOR    ${item}    IN    @{items}
        ${full_path}=    Set Variable    ${EXECDIR}${/}${item}
        ${is_uuid}=    Evaluate    len($item) == 32 and all(c in "0123456789abcdef" for c in $item)
        ${is_known_temp}=    Evaluate    $item in $TEMP_FILES
        IF    ${is_uuid} or ${is_known_temp}
            ${is_file}=    Run Keyword And Return Status    File Should Exist    ${full_path}
            IF    ${is_file}
                Log    Removing temp file: ${item}
                Remove File    ${full_path}
            END
        END
    END

Cleanup Download Suite
    [Documentation]     Closes all active browser sessions and removes temporary runtime artifacts created during the Salesforce file download suite.
    Close All Browsers
    Cleanup Runtime Artifacts
