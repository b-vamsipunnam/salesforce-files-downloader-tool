*** Settings ***
Documentation     CI smoke test – validates libraries and Selenium startup only
Library           SeleniumLibrary
Library           ../../src/robot/library/ExcelLibrary.py

Suite Setup       Open Browser For Smoke
Suite Teardown    Close All Browsers

*** Variables ***
${URL}    https://example.com

*** Test Cases ***
CI Smoke – Framework Boots
    Title Should Be    Example Domain

CI Smoke – Excel Wrapper Works
    Create Excel Document    smoke_doc
    Write Excel Cell         1    1    Hello CI
    Close All Excel Documents

*** Keywords ***
Open Browser For Smoke
    ${opts}=    Evaluate    sys.modules['selenium.webdriver'].ChromeOptions()    sys, selenium.webdriver
    Call Method    ${opts}    add_argument    --headless=new
    Call Method    ${opts}    add_argument    --no-sandbox
    Call Method    ${opts}    add_argument    --disable-dev-shm-usage
    Call Method    ${opts}    add_argument    --disable-gpu
    Call Method    ${opts}    add_argument    --window-size=1920,1080
    Open Browser    ${URL}    chrome    options=${opts}
