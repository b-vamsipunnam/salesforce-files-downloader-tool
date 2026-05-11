*** Settings ***
Documentation                              Automates bulk download of Salesforce files using ContentDocument IDs and stores them locally in ID-based folders.
Resource                                   ../resources/keywords.robot
Suite Teardown                             Cleanup Suite

*** Variables ***
${input_excel_path1}                       ${input_folder}${/}Inputfile_1.xlsx
${input_excel_path2}                       ${input_folder}${/}Inputfile_2.xlsx
${sheet_name}                              Input
# Generate Data Loader-ready Excel files.
# Accepted values: Yes / No
${GENERATE_CONTENT_VERSION_FILE}           Yes
${GENERATE_CONTENT_DOCUMENT_LINK_FILE}     Yes

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