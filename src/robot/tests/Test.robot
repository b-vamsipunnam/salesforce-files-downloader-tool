*** Settings ***
Documentation                   Automation scirpt to download the Salesforce files using ContentDocumentIDs
...                             Developed this automation script, that logs into the Any SFDC environment, retrieves ContentDocumentIDs from a source file, Builds download URL and automatically downloads the files to a specified local path.
...                             The script is designed to downloaded with each file retaining its original name and then creates a folder with a Name ContentdocumentID
...                             and moves the downloaded file into it.
Resource                        Support.robot
Suite Teardown                  Close All Browsers

*** Variables ***
${input_excel_path1}                       ${input_folder}/Inputfile_1.xlsx
${input_excel_path2}                       ${input_folder}/Inputfile_2.xlsx
${sheet_name}                              Input

*** Test Cases ***
Download_Files_Batch_1
    Download the SFDC files using the ContentDocumentIDs        ${input_excel_path1}        ${sheet_name}

Download_Files_Batch_2
    Download the SFDC files using the ContentDocumentIDs        ${input_excel_path2}        ${sheet_name}
