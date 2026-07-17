*** Settings ***
Documentation       CI smoke test that validates library imports, Selenium startup, and the Excel wrapper

Library             SeleniumLibrary
Library             ../../src/robot/libraries/ExcelLibrary.py


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


*** Keywords ***
Open Browser For Smoke
    ${opts}=    Evaluate    __import__("selenium.webdriver").webdriver.ChromeOptions()
    Call Method    ${opts}    add_argument    --headless\=new
    Call Method    ${opts}    add_argument    --no-sandbox
    Call Method    ${opts}    add_argument    --disable-dev-shm-usage
    Call Method    ${opts}    add_argument    --disable-gpu
    Call Method    ${opts}    add_argument    --window-size\=1920,1080
    Open Browser    ${URL}    chrome    options=${opts}
