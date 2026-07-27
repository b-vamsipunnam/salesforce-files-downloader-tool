*** Settings ***
Documentation       CI smoke test that validates library imports, Selenium startup, and the Excel wrapper

Library             SeleniumLibrary
Library             ../../src/robot/libraries/ExcelLibrary.py
Resource            ../../src/robot/resources/salesforce_cli.robot
Resource            ../../src/robot/resources/salesforce_api.robot
Resource            ../../src/robot/resources/download_operations.robot
Resource            ../../src/robot/resources/download_workflow.robot


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
    Log To Console    Minimum Estimated Metadata Requests: 2
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

CI Smoke – Removes Moved Binary When Workbook Transaction Fails
    ${download_directory}=    Set Variable
    ...    ${EXECDIR}${/}.review_transaction_failure
    ${content_id}=    Set Variable    069000000000001
    ${content_id_folder}=    Set Variable
    ...    ${download_directory}${/}${content_id}
    Create Directory    ${content_id_folder}
    Create File    ${download_directory}${/}download.bin    data
    ${failed_content_ids}=    Create List
    ${successful_content_ids}=    Create List
    ${content_links}=    Create List
    Set Test Variable    ${FILE_STABILITY_INTERVAL}    0s

    ${status}=    Validate And Move Downloaded File
    ...    download.bin
    ...    ${content_id}
    ...    ${content_links}
    ...    2
    ...    2
    ...    2
    ...    ${download_directory}${/}missing_cv.xlsx
    ...    ${download_directory}${/}missing_cdl.xlsx
    ...    Test file
    ...    ${failed_content_ids}
    ...    ${content_id_folder}
    ...    ${download_directory}
    ...    final.bin
    ...    Yes
    ...    No
    ...    4
    ...    ${successful_content_ids}

    Should Be Equal    ${status}    FAIL
    Should Contain    ${failed_content_ids}    ${content_id}
    Should Be Empty    ${successful_content_ids}
    Directory Should Not Exist    ${content_id_folder}
    File Should Not Exist    ${content_id_folder}${/}final.bin
    [Teardown]    Run Keyword And Ignore Error
    ...    Remove Directory
    ...    ${download_directory}
    ...    recursive=True

CI Smoke – Normalizes Yes Or No Settings
    ${yes}=    Validate And Normalize Yes Or No Setting
    ...    GENERATE_CONTENT_VERSION_FILE
    ...    ${SPACE}yEs${SPACE}
    ${no}=    Validate And Normalize Yes Or No Setting
    ...    GENERATE_CONTENT_DOCUMENT_LINK_FILE
    ...    NO
    Should Be Equal    ${yes}    Yes
    Should Be Equal    ${no}    No

CI Smoke – Rejects Invalid Yes Or No Setting
    Run Keyword And Expect Error
    ...    GENERATE_CONTENT_VERSION_FILE must be Yes or No. Received: Yse
    ...    Validate And Normalize Yes Or No Setting
    ...    GENERATE_CONTENT_VERSION_FILE
    ...    Yse

CI Smoke – Canonicalizes Equivalent Salesforce IDs
    ${short_id}=    Set Variable    069AAAAAAAAAAAA
    ${long_id}=    Set Variable    069AAAAAAAAAAAAY55
    ${canonical_short}=    Canonicalize Content Document Id    ${short_id}
    ${canonical_long}=    Canonicalize Content Document Id    ${long_id}
    Should Be Equal    ${canonical_short}    ${long_id}
    Should Be Equal    ${canonical_long}    ${long_id}

CI Smoke – Deduplicates Mixed 15 And 18 Character IDs From Excel
    ${input_file}=    Set Variable
    ...    ${EXECDIR}${/}.review_canonical_ids.xlsx
    Create Excel Document    ${input_file}
    Write Excel Cell    1    1    ContentDocumentId
    Write Excel Cell    2    1    069AAAAAAAAAAAA
    Write Excel Cell    3    1    069AAAAAAAAAAAAY55
    Save Excel Document
    Close Current Excel Document
    @{content_ids}=    Read Content IDs From Excel Sheet
    ...    ${input_file}
    ...    Sheet
    Length Should Be    ${content_ids}    1
    Should Be Equal    ${content_ids}[0]    069AAAAAAAAAAAAY55
    [Teardown]    Run Keywords
    ...    Run Keyword And Ignore Error    Close All Excel Documents
    ...    AND
    ...    Run Keyword And Ignore Error    Remove File    ${input_file}

CI Smoke – API Capacity Validation Passes
    Validate Salesforce API Capacity    1000    600    25    100

CI Smoke – API Capacity Validation Fails
    Run Keyword And Expect Error
    ...    Insufficient Salesforce API capacity.*
    ...    Validate Salesforce API Capacity
    ...    700
    ...    600
    ...    25
    ...    100

CI Smoke – CLI Limit Lookup Retries Then Succeeds
    ${failed}=    Create Dictionary
    ...    rc=1
    ...    stdout=${EMPTY}
    ...    stderr=temporary failure
    ${valid_output}=    Set Variable
    ...    {"result":[{"name":"DailyApiRequests","max":100000,"remaining":90000}]}
    ${successful}=    Create Dictionary
    ...    rc=0
    ...    stdout=${valid_output}
    ...    stderr=${EMPTY}
    ${results}=    Create List    ${failed}    ${successful}
    Set Test Variable    ${MOCK_CLI_RESULTS}    ${results}
    Set Test Variable    ${sf_cli_path}    mock-sf
    Set Test Variable    ${SF_ORG_ALIAS}    mock-org
    Set Test Variable    ${API_LIMIT_LOOKUP_RETRY_DELAY}    0s
    ${maximum}    ${remaining}=    Get Salesforce Daily API Limits
    ...    Run Mock Salesforce CLI Process
    Should Be Equal As Integers    ${maximum}    100000
    Should Be Equal As Integers    ${remaining}    90000
    Should Be Empty    ${MOCK_CLI_RESULTS}

CI Smoke – CLI Limit Lookup Fails After All Attempts
    ${failed}=    Create Dictionary
    ...    rc=1
    ...    stdout=${EMPTY}
    ...    stderr=permanent failure
    ${results}=    Create List    ${failed}    ${failed}    ${failed}
    Set Test Variable    ${MOCK_CLI_RESULTS}    ${results}
    Set Test Variable    ${sf_cli_path}    mock-sf
    Set Test Variable    ${SF_ORG_ALIAS}    mock-org
    Set Test Variable    ${API_LIMIT_LOOKUP_RETRY_DELAY}    0s
    Run Keyword And Expect Error
    ...    Unable to retrieve Salesforce DailyApiRequests after 3 attempts.*
    ...    Get Salesforce Daily API Limits
    ...    Run Mock Salesforce CLI Process
    Should Be Empty    ${MOCK_CLI_RESULTS}

CI Smoke – SOQL Query Follows Pagination
    Set Test Variable    ${api_version}    61.0
    ${first_record}=    Create Dictionary    Id=069AAAAAAAAAAAAY55
    ${second_record}=    Create Dictionary    Id=069BBBBBBBBBBBBY55
    ${first_records}=    Create List    ${first_record}
    ${second_records}=    Create List    ${second_record}
    ${first_page}=    Create Dictionary
    ...    done=${FALSE}
    ...    nextRecordsUrl=/services/data/v61.0/query/next
    ...    records=${first_records}
    ${second_page}=    Create Dictionary
    ...    done=${TRUE}
    ...    records=${second_records}
    ${pages}=    Create List    ${first_page}    ${second_page}
    Set Test Variable    ${MOCK_SOQL_PAGES}    ${pages}
    ${records}=    Execute SOQL Query
    ...    SELECT Id FROM ContentDocument
    ...    mock-session
    ...    Return Mock Salesforce Page
    Length Should Be    ${records}    2
    Should Be Equal    ${records}[0][Id]    069AAAAAAAAAAAAY55
    Should Be Equal    ${records}[1][Id]    069BBBBBBBBBBBBY55
    Should Be Empty    ${MOCK_SOQL_PAGES}

CI Smoke – SOQL Query Rejects Missing Next URL
    Set Test Variable    ${api_version}    61.0
    ${records}=    Create List
    ${page}=    Create Dictionary
    ...    done=${FALSE}
    ...    records=${records}
    ${pages}=    Create List    ${page}
    Set Test Variable    ${MOCK_SOQL_PAGES}    ${pages}
    Run Keyword And Expect Error
    ...    Salesforce returned done=false without nextRecordsUrl on page 1.
    ...    Execute SOQL Query
    ...    SELECT Id FROM ContentDocument
    ...    mock-session
    ...    Return Mock Salesforce Page

CI Smoke – Validates ContentDocument IDs
    ${valid_15}=    Is Valid ContentDocument ID    069AAAAAAAAAAAA
    ${valid_18}=    Is Valid ContentDocument ID    069AAAAAAAAAAAAY55
    ${wrong_prefix}=    Is Valid ContentDocument ID    001AAAAAAAAAAAA
    ${invalid}=    Is Valid ContentDocument ID    not-an-id
    Should Be True    ${valid_15}
    Should Be True    ${valid_18}
    Should Not Be True    ${wrong_prefix}
    Should Not Be True    ${invalid}

CI Smoke – Metadata Map Is Empty When Record Is Not Found
    Set Test Variable    ${session_alias}    mock-session
    ${empty_records}=    Create List
    ${responses}=    Create List    ${empty_records}
    Set Test Variable    ${MOCK_SOQL_RECORDS}    ${responses}
    ${content_ids}=    Create List    069AAAAAAAAAAAAY55
    ${metadata}=    Get ContentDocument Metadata Map
    ...    ${content_ids}
    ...    200
    ...    Return Mock SOQL Records
    Should Be Empty    ${metadata}

CI Smoke – Preserves Multiple ContentDocument Links
    Set Test Variable    ${session_alias}    mock-session
    ${first_link}=    Create Dictionary
    ...    ContentDocumentId=069AAAAAAAAAAAAY55
    ...    Id=06A000000000001
    ...    LinkedEntityId=001000000000001
    ...    ShareType=V
    ...    Visibility=AllUsers
    ${second_link}=    Create Dictionary
    ...    ContentDocumentId=069AAAAAAAAAAAAY55
    ...    Id=06A000000000002
    ...    LinkedEntityId=001000000000002
    ...    ShareType=I
    ...    Visibility=InternalUsers
    ${links}=    Create List    ${first_link}    ${second_link}
    ${responses}=    Create List    ${links}
    Set Test Variable    ${MOCK_SOQL_RECORDS}    ${responses}
    ${content_ids}=    Create List    069AAAAAAAAAAAAY55
    ${metadata}=    Get ContentDocumentLink Metadata Map
    ...    ${content_ids}
    ...    200
    ...    Return Mock SOQL Records
    Length Should Be    ${metadata}[069AAAAAAAAAAAAY55]    2


*** Keywords ***
Run Mock Salesforce CLI Process
    [Arguments]    @{arguments}
    ${result}=    Remove From List    ${MOCK_CLI_RESULTS}    0
    ${response}=    Evaluate
    ...    types.SimpleNamespace(**$result)
    ...    modules=types
    RETURN    ${response}

Return Mock Salesforce Page
    [Arguments]    ${session_alias}    ${url}    ${params}=${NONE}
    ${payload}=    Remove From List    ${MOCK_SOQL_PAGES}    0
    ${response}=    Evaluate
    ...    type("MockResponse", (), {"json": lambda self, payload=$payload: payload})()
    RETURN    ${response}

Return Mock SOQL Records
    [Arguments]    ${soql}    ${session_alias}
    ${records}=    Remove From List    ${MOCK_SOQL_RECORDS}    0
    RETURN    ${records}

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
