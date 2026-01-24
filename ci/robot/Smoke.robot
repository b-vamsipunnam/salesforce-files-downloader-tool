*** Settings ***
Documentation                       CI smoke test – validates libraries and Selenium startup only
Library                             SeleniumLibrary
Library                             ../../src/robot/library/ExcelLibrary.py

*** Variables ***
${URL}                              https://example.com

*** Test Cases ***
CI Smoke – Framework Boots
    Open Browser For Smoke
    Title Should Be                 Example Domain
    Close All Browsers

CI Smoke – Excel Wrapper Works
    Create Excel Document           smoke_doc
    Write Excel Cell                1    1    Hello CI
    Close All Excel Documents

*** Keywords ***
Open Browser For Smoke
    ${opts}=                        Evaluate            __import__("selenium.webdriver").webdriver.ChromeOptions()
    ${a1}=                          Set Variable        --headless
    ${a2}=                          Set Variable        --no-sandbox
    ${a3}=                          Set Variable        --disable-dev-shm-usage
    ${a4}=                          Set Variable        --disable-gpu
    ${a5}=                          Set Variable        --window-size=1920,1080
    Call Method                     ${opts}             add_argument            ${a1}
    Call Method                     ${opts}             add_argument            ${a2}
    Call Method                     ${opts}             add_argument            ${a3}
    Call Method                     ${opts}             add_argument            ${a4}
    Call Method                     ${opts}             add_argument            ${a5}
    Open Browser                    ${URL}              chrome                  options=${opts}


