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

CI Smoke – Sanitizes Windows Reserved Filename
    ${safe}=    Sanitize Filename    CON.txt
    Should Be Equal    ${safe}    _CON.txt

CI Smoke – Sanitizes Empty Filename
    ${safe}=    Sanitize Filename    ...
    Should Be Equal    ${safe}    salesforce_file

CI Smoke – Sanitizes Trailing Periods And Spaces
    ${safe}=    Sanitize Filename    report...
    Should Be Equal    ${safe}    report

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
    ${opts}=    Evaluate    __import__("selenium.webdriver").webdriver.ChromeOptions()
    Call Method    ${opts}    add_argument    --headless\=new
    Call Method    ${opts}    add_argument    --no-sandbox
    Call Method    ${opts}    add_argument    --disable-dev-shm-usage
    Call Method    ${opts}    add_argument    --disable-gpu
    Call Method    ${opts}    add_argument    --window-size\=1920,1080
    Open Browser    ${URL}    chrome    options=${opts}
