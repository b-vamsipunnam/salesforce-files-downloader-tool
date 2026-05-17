*** Settings ***
Documentation                              Automates bulk download of Salesforce files using ContentDocument IDs and stores them locally in ID-based folders.
Resource                                   ../resources/keywords.robot
Suite Teardown                             Cleanup Suite

*** Variables ***
${INPUT_EXCEL_PATH_1}                      ${INPUT_FOLDER}${/}Inputfile_1.xlsx
${INPUT_EXCEL_PATH_2}                      ${INPUT_FOLDER}${/}Inputfile_2.xlsx
${SHEET_NAME}                              Input
# Generate Data Loader-ready Excel files.
# Accepted values: Yes / No
${GENERATE_CONTENT_VERSION_FILE}           No
${GENERATE_CONTENT_DOCUMENT_LINK_FILE}     No

*** Test Cases ***
Download_Batch_1
    Download Files Using Content Document IDs
    ...    ${INPUT_EXCEL_PATH_1}
    ...    ${SHEET_NAME}
    ...    ${GENERATE_CONTENT_VERSION_FILE}
    ...    ${GENERATE_CONTENT_DOCUMENT_LINK_FILE}

Download_Batch_2
    Download Files Using Content Document IDs
    ...    ${INPUT_EXCEL_PATH_2}
    ...    ${SHEET_NAME}
    ...    ${GENERATE_CONTENT_VERSION_FILE}
    ...    ${GENERATE_CONTENT_DOCUMENT_LINK_FILE}