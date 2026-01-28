*** Settings ***
Documentation                   Automates bulk download of Salesforce files using ContentDocument IDs and stores them locally in ID-based folders.
Resource                        Support.robot
Suite Teardown                  Close All Browsers

*** Variables ***
${input_excel_path1}            ${input_folder}/Inputfile_1.xlsx
${input_excel_path2}            ${input_folder}/Inputfile_2.xlsx
${sheet_name}                   Input

*** Test Cases ***
Download_Batch_1
    Download Files Using Content Document IDs        ${input_excel_path1}        ${sheet_name}

Download_Batch_2
    Download Files Using Content Document IDs        ${input_excel_path2}        ${sheet_name}
