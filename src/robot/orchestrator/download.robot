*** Settings ***
Documentation       Automates bulk download of Salesforce files using ContentDocument IDs and stores them locally in ID-based folders.

Resource            ../resources/keywords.robot

Suite Teardown      Cleanup Suite


*** Variables ***
# Input Excel files and worksheet used for ContentDocumentId processing.
${INPUT_EXCEL_PATH_1}                       ${INPUT_FOLDER}${/}Inputfile_1.xlsx
${INPUT_EXCEL_PATH_2}                       ${INPUT_FOLDER}${/}Inputfile_2.xlsx
${INPUT_EXCEL_PATH_3}                       ${INPUT_FOLDER}${/}Inputfile_3.xlsx
${INPUT_EXCEL_PATH_4}                       ${INPUT_FOLDER}${/}Inputfile_4.xlsx
${SHEET_NAME}                               Input

# Controls optional generation of Data Loader-ready ContentVersion and ContentDocumentLink Excel files.
# Accepted values: Yes / No
${GENERATE_CONTENT_VERSION_FILE}            Yes
${GENERATE_CONTENT_DOCUMENT_LINK_FILE}      Yes


*** Test Cases ***
Download_Batch_1
    [Documentation]    Downloads files listed in Inputfile_1.xlsx.
    Download Files Using Content Document IDs
    ...    ${INPUT_EXCEL_PATH_1}
    ...    ${SHEET_NAME}
    ...    ${GENERATE_CONTENT_VERSION_FILE}
    ...    ${GENERATE_CONTENT_DOCUMENT_LINK_FILE}

Download_Batch_2
    [Documentation]    Downloads files listed in Inputfile_2.xlsx.
    Download Files Using Content Document IDs
    ...    ${INPUT_EXCEL_PATH_2}
    ...    ${SHEET_NAME}
    ...    ${GENERATE_CONTENT_VERSION_FILE}
    ...    ${GENERATE_CONTENT_DOCUMENT_LINK_FILE}

Download_Batch_3
    [Documentation]    Downloads files listed in Inputfile_3.xlsx.
    Download Files Using Content Document IDs
    ...    ${INPUT_EXCEL_PATH_3}
    ...    ${SHEET_NAME}
    ...    ${GENERATE_CONTENT_VERSION_FILE}
    ...    ${GENERATE_CONTENT_DOCUMENT_LINK_FILE}

Download_Batch_4
    [Documentation]    Downloads files listed in Inputfile_4.xlsx.
    Download Files Using Content Document IDs
    ...    ${INPUT_EXCEL_PATH_4}
    ...    ${SHEET_NAME}
    ...    ${GENERATE_CONTENT_VERSION_FILE}
    ...    ${GENERATE_CONTENT_DOCUMENT_LINK_FILE}
