*** Settings ***
Documentation       CI smoke test that validates library imports, Selenium startup, and the Excel wrapper

Library             SeleniumLibrary
Library             ../../src/robot/libraries/ExcelLibrary.py
Resource            ../../src/robot/resources/salesforce_cli.robot
Resource            ../../src/robot/resources/download_operations.robot


*** Variables ***
${URL}      https://example.com


*** Test Cases ***
CI Smoke – Framework Boots
    Open Browser For Smoke
    Title Should Be    Example Domain
    [Teardown]    Close All Browsers

CI Smoke – Excel Wrapper Works
    Create Excel Document    smoke_doc
    Write Excel Cell    1    1    Hello CI
    [Teardown]    Close All Excel Documents

CI Smoke – Parses JSON Object With Leading Warning
    ${raw_output}=    Catenate
    ...    SEPARATOR=\n
    ...    Warning: plugin update available
    ...    {"status": 0}
    ${data}=    Safe Parse Sf Json    ${raw_output}
    Should Be Equal As Integers    ${data}[status]    0

CI Smoke – Parses JSON Array With Leading Warning
    ${raw_output}=    Catenate
    ...    SEPARATOR=\n
    ...    Warning: plugin update available
    ...    [{"status": 0}]
    ${data}=    Safe Parse Sf Json    ${raw_output}
    Should Be Equal As Integers    ${data}[0][status]    0

CI Smoke – Ignores Text After JSON
    ${raw_output}=    Catenate
    ...    SEPARATOR=\n
    ...    {"status": 0}
    ...    Additional CLI message
    ${data}=    Safe Parse Sf Json    ${raw_output}
    Should Be Equal As Integers    ${data}[status]    0

CI Smoke – Skips JSON Markers In Leading Warning
    ${raw_output}=    Catenate
    ...    SEPARATOR=\n
    ...    Warning: plugin [legacy] contains {invalid} metadata
    ...    {"status": 0}
    ${data}=    Safe Parse Sf Json    ${raw_output}
    Should Be Equal As Integers    ${data}[status]    0

CI Smoke – Rejects Output Without JSON
    Run Keyword And Expect Error
    ...    Invalid sf CLI JSON output
    ...    Safe Parse Sf Json
    ...    Warning: plugin update available

CI Smoke – Rejects Malformed JSON
    Run Keyword And Expect Error
    ...    Invalid sf CLI JSON output
    ...    Safe Parse Sf Json
    ...    {"status":

CI Smoke – Estimates Metadata API Requests With Links
    ${batches}    ${requests}=    Estimate Metadata API Requests    401    Yes
    Should Be Equal As Integers    ${batches}    3
    Should Be Equal As Integers    ${requests}    6

CI Smoke – Estimates Metadata API Requests Without Links
    ${batches}    ${requests}=    Estimate Metadata API Requests    401    No
    Should Be Equal As Integers    ${batches}    3
    Should Be Equal As Integers    ${requests}    3

CI Smoke – Allows Disabled API Capacity Check
    Set Test Variable    ${ENABLE_API_CAPACITY_CHECK}    ${FALSE}
    Check Salesforce API Capacity    100    Yes

CI Smoke – Pabot Lock Is Available
    pabot.PabotLib.Acquire Lock    smoke_salesforce_cli_lock
    TRY
        Log    Cross-process lock acquired.
    FINALLY
        pabot.PabotLib.Release Lock    smoke_salesforce_cli_lock
    END

CI Smoke – Logs API Capacity Values
    Set Test Variable    ${SF_ORG_ALIAS}    DemoHub
    Log To Console    Org Alias: ${SF_ORG_ALIAS}
    Log To Console    Daily API Maximum: 100000
    Log To Console    Daily API Remaining: 99999
    Log To Console    Estimated Metadata Requests: 2
    Log To Console    API Capacity Check Requests: 1
    Log To Console    Estimated Tool Requests: 3
    Log To Console    Projected API Requests Remaining: 99996

CI Smoke – Sanitizes Windows Reserved Filename
    ${safe}=    Sanitize Filename    CON.txt
    Should Be Equal    ${safe}    _CON.txt

CI Smoke – Sanitizes Empty Filename
    ${safe}=    Sanitize Filename    ...
    Should Be Equal    ${safe}    salesforce_file

CI Smoke – Sanitizes Trailing Periods And Spaces
    ${safe}=    Sanitize Filename    report...
    Should Be Equal    ${safe}    report

CI Smoke – Sanitizes Windows Invalid Characters
    ${safe}=    Sanitize Filename    Download Files: Batch 1?*
    Should Be Equal    ${safe}    Download Files_ Batch 1__

CI Smoke – Limits Sanitized Filename Length
    ${safe}=    Sanitize Local Filename    abcdefghijklmnop.txt    max_length=12
    Should Be Equal    ${safe}    abcdefgh.txt

CI Smoke – Prevents Reserved Name After Truncation
    ${safe}=    Sanitize Local Filename    CONSOLE    max_length=3
    Should Be Equal    ${safe}    _CO

CI Smoke – Normalizes Reserved Stem Before Extension
    ${safe}=    Sanitize Local Filename    CON${SPACE}.txt
    Should Be Equal    ${safe}    _CON.txt

CI Smoke – Sanitizes Reserved Fallback
    ${safe}=    Sanitize Local Filename    ...    fallback=AUX.txt
    Should Be Equal    ${safe}    _AUX.txt

CI Smoke – Uses Fallback For None
    ${safe}=    Sanitize Local Filename    ${NONE}
    Should Be Equal    ${safe}    salesforce_file

CI Smoke – Handles One Character Limit
    ${safe}=    Sanitize Local Filename    CON    max_length=1
    Should Be Equal    ${safe}    C

CI Smoke – Cleans Directory With Apostrophe
    ${directory}=    Set Variable
    ...    ${EXECDIR}${/}.review_O'Brien
    Create Directory    ${directory}
    Create File    ${directory}${/}temporary.txt    temporary
    Cleanup Download Directory    ${directory}
    Directory Should Be Empty    ${directory}
    [Teardown]    Run Keyword And Ignore Error
    ...    Remove Directory
    ...    ${directory}
    ...    recursive=True


*** Keywords ***
Open Browser For Smoke
    [Documentation]    Opens headless Chrome with bounded retries for transient startup exits.
    ${opts}=    Evaluate    __import__("selenium.webdriver").webdriver.ChromeOptions()
    Call Method    ${opts}    add_argument    --headless\=new
    Call Method    ${opts}    add_argument    --no-sandbox
    Call Method    ${opts}    add_argument    --disable-dev-shm-usage
    Call Method    ${opts}    add_argument    --disable-gpu
    Call Method    ${opts}    add_argument    --disable-extensions
    Call Method    ${opts}    add_argument    --disable-background-networking
    Call Method    ${opts}    add_argument    --no-first-run
    Call Method    ${opts}    add_argument    --no-default-browser-check
    Call Method    ${opts}    add_argument    --remote-debugging-port\=0
    Call Method    ${opts}    add_argument    --window-size\=1920,1080
    Wait Until Keyword Succeeds    3x    2s
    ...    Open Chrome For Smoke
    ...    ${opts}

Open Chrome For Smoke
    [Documentation]    Clears any failed Selenium state before one Chrome startup attempt.
    [Arguments]    ${opts}
    Run Keyword And Ignore Error    Close All Browsers
    Open Browser    ${URL}    chrome    options=${opts}
