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
*** Keywords ***
Open Browser For Smoke
    ${chrome_options}=    Evaluate    sys.modules['selenium.webdriver'].ChromeOptions()    sys, selenium.webdriver
    Call Method    ${chrome_options}    add_argument    --headless=new
    Call Method    ${chrome_options}    add_argument    --no-sandbox
    Call Method    ${chrome_options}    add_argument    --disable-dev-shm-usage
    Call Method    ${chrome_options}    add_argument    --disable-gpu
    Call Method    ${chrome_options}    add_argument    --window-size=1920,1080
    Open Browser    ${URL}    chrome    options=${chrome_options}
