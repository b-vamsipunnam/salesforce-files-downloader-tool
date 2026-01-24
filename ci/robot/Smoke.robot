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
    # SeleniumLibrary-compatible way: pass ChromeOptions args as a single string
    Open Browser    ${URL}    chrome
    ...    options=add_argument(--headless=new);add_argument(--no-sandbox);add_argument(--disable-dev-shm-usage);add_argument(--disable-gpu);add_argument(--window-size=1920,1080)
