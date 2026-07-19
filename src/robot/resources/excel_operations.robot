*** Settings ***
Documentation       Reads ContentDocument IDs and creates, updates, and manages Excel files used for migration and failure reporting.

Library             OperatingSystem
Library             Collections
Library             String
Library             ../libraries/ExcelLibrary.py
Resource            configuration.robot


*** Keywords ***
Read Content IDs From Excel Sheet
    [Documentation]     Reads ContentDocument IDs from the first column of the supplied Excel sheet. Removes an optional ContentDocumentId header, ignores blank values, trims whitespace, removes duplicates, and returns the resulting list.
    [Arguments]    ${input_excel_path}    ${sheet_name}
    ${input_excel_path}=    Normalize Path    ${input_excel_path}
    Open Excel Document    filename=${input_excel_path}    doc_id=${sheet_name}
    @{column_values}=    Read Excel Column    1    0    0    ${sheet_name}
    Close Current Excel Document
    ${count}=    Get Length    ${column_values}
    IF    ${count} == 0    RETURN    @{EMPTY}
    ${first}=    Strip String    ${column_values}[0]
    ${first_lower}=    Evaluate    str($first).lower()    modules=builtins
    IF    '${first_lower}' == 'contentdocumentid'
        Remove From List    ${column_values}    0
    END
    ${count}=    Get Length    ${column_values}
    IF    ${count} == 0    RETURN    @{EMPTY}
    ${content_ids}=    Create List
    FOR    ${value}    IN    @{column_values}
        ${str_value}=    Convert To String    ${value}
        ${id_value}=    Strip String    ${str_value}
        IF    '${id_value}' == '${EMPTY}' or '${id_value}' == '${NONE}'
            CONTINUE
        END
        Append To List    ${content_ids}    ${id_value}
    END
    ${content_ids}=    Remove Duplicates    ${content_ids}
    RETURN    ${content_ids}

Create ContentVersion Excel File
    [Documentation]     Creates a ContentVersion Data Loader workbook in the supplied output directory, writes the required import headers, and returns the first available data row and generated workbook path.
    [Arguments]    ${download_directory}
    ${proper_test_name}=    Replace String    ${TEST NAME}    ${SPACE}    _
    ${cv_file_name}=    Set Variable    ${download_directory}${/}${proper_test_name}_ContentVersion_Import.xlsx
    Create Excel Document    doc_id=CV_DOC
    Write Excel Cell    row_num=1    col_num=1    value=Title
    Write Excel Cell    row_num=1    col_num=2    value=VersionData
    Write Excel Cell    row_num=1    col_num=3    value=PathOnClient
    # Write Excel Cell    row_num=1    col_num=4    value=Description
    # Write Excel Cell    row_num=1    col_num=5    value=FirstPublishLocationId
    Save Excel Document    filename=${cv_file_name}
    Close Current Excel Document
    ${first_data_row}=    Set Variable    2
    RETURN    ${first_data_row}    ${cv_file_name}

Create ContentDocumentLink Excel File
    [Documentation]     Creates a ContentDocumentLink Data Loader workbook in the supplied output directory, writes the required import headers, and returns the first available data row and generated workbook path.
    [Arguments]    ${download_directory}
    ${proper_test_name}=    Replace String    ${TEST NAME}    ${SPACE}    _
    ${cdl_file_name}=    Set Variable    ${download_directory}${/}${proper_test_name}_ContentDocumentLink_Import.xlsx
    Create Excel Document    doc_id=CDL_DOC
    Write Excel Cell    row_num=1    col_num=1    value=ContentDocumentId
    Write Excel Cell    row_num=1    col_num=2    value=LinkedEntityID
    Write Excel Cell    row_num=1    col_num=3    value=ShareType
    Write Excel Cell    row_num=1    col_num=4    value=Visibility
    Save Excel Document    filename=${cdl_file_name}
    Close Current Excel Document
    ${first_data_row}=    Set Variable    2
    RETURN    ${first_data_row}    ${cdl_file_name}

Write Failed ContentDocument IDs To Excel
    [Documentation]     Creates a test-specific failed-ID workbook in the supplied output directory when one or more ContentDocument downloads have failed.
    [Arguments]    ${unique_failed_content_ids}    ${output_directory}
    ${test_name}=    Replace String    ${TEST NAME}    ${SPACE}    _
    ${excel_file}=    Set Variable    ${output_directory}${/}${test_name}_FAILED_IDs.xlsx
    ${no_of_records}=    Get Length    ${unique_failed_content_ids}
    IF    '${no_of_records}' != '0'
        Write Failed ContentDocument IDs    ${unique_failed_content_ids}    ${excel_file}
    END

Remove Empty Import Files
    [Documentation]     Removes generated ContentVersion and ContentDocumentLink workbooks when no files were downloaded successfully. Ignores workbooks that were not requested or do not exist.
    [Arguments]    ${cv_file_name}    ${cdl_file_name}
    IF    $cv_file_name is not None
        ${cv_file_exists}=    Run Keyword And Return Status
        ...    File Should Exist
        ...    ${cv_file_name}
        IF    ${cv_file_exists}
            ${cv_remove_status}    ${cv_remove_message}=    Run Keyword And Ignore Error
            ...    Remove File
            ...    ${cv_file_name}
            IF    '${cv_remove_status}' == 'PASS'
                Log To Console
                ...    ContentVersion import file removed because no files were downloaded successfully.
            ELSE
                Log To Console
                ...    WARNING: Unable to remove empty ContentVersion import file: ${cv_remove_message}
            END
        END
    END
    IF    $cdl_file_name is not None
        ${cdl_file_exists}=    Run Keyword And Return Status
        ...    File Should Exist
        ...    ${cdl_file_name}
        IF    ${cdl_file_exists}
            ${cdl_remove_status}    ${cdl_remove_message}=    Run Keyword And Ignore Error
            ...    Remove File
            ...    ${cdl_file_name}
            IF    '${cdl_remove_status}' == 'PASS'
                Log To Console
                ...    ContentDocumentLink import file removed because no files were downloaded successfully.
            ELSE
                Log To Console
                ...    WARNING: Unable to remove empty ContentDocumentLink import file: ${cdl_remove_message}
            END
        END
    END

Write Failed ContentDocument IDs
    [Documentation]     Creates an Excel workbook containing the supplied failed ContentDocument IDs under the ContentDocumentId header for reporting or later retry.
    [Arguments]    ${unique_failed_content_ids}    ${excel_file}
    ${uuid}=    Evaluate    __import__('uuid').uuid4().hex
    Create Excel Document    ${uuid}
    Write Excel Cell    row_num=1    col_num=1    value=ContentDocumentId
    ${row}=    Set Variable    2
    FOR    ${id}    IN    @{unique_failed_content_ids}
        Write Excel Cell    row_num=${row}    col_num=1    value=${id}
        ${row}=    Evaluate    ${row} + 1
    END
    Save Excel Document    filename=${excel_file}
    Close Current Excel Document

Write ContentVersion Row
    [Documentation]     Writes one ContentVersion import row containing the Salesforce file title, local VersionData path, and PathOnClient value, then saves and closes the workbook.
    [Arguments]    ${cv_row}    ${dst}    ${cv_file_name}    ${file_title}
    Open Excel Document    filename=${cv_file_name}    doc_id=CV_DOC
    Write Excel Cell    row_num=${cv_row}    col_num=1    value=${file_title}
    Write Excel Cell    row_num=${cv_row}    col_num=2    value=${dst}
    Write Excel Cell    row_num=${cv_row}    col_num=3    value=${dst}
    # Intentionally kept these commented lines for futures use.
    # Write Excel Cell    row_num=${cv_row}    col_num=4    value=${description}
    # Write Excel Cell    row_num=${cv_row}    col_num=5    value=FirstPublishLocationId
    Save Excel Document    filename=${cv_file_name}
    Close Current Excel Document

Write ContentDocumentLink Row
    [Documentation]     Writes one ContentDocumentLink import row containing the source ContentDocument ID, linked entity ID, share type, and visibility, then saves and closes the workbook.
    [Arguments]    ${cdl_row}    ${content_link}    ${cdl_file_name}
    ${document_id}=    Get From Dictionary    ${content_link}    ContentDocumentId
    ${linked_entity_id}=    Get From Dictionary    ${content_link}    LinkedEntityId
    ${share_type}=    Get From Dictionary    ${content_link}    ShareType
    ${visibility}=    Get From Dictionary    ${content_link}    Visibility
    Open Excel Document    filename=${cdl_file_name}    doc_id=CDL_DOC
    Write Excel Cell    row_num=${cdl_row}    col_num=1    value=${document_id}
    Write Excel Cell    row_num=${cdl_row}    col_num=2    value=${linked_entity_id}
    Write Excel Cell    row_num=${cdl_row}    col_num=3    value=${share_type}
    Write Excel Cell    row_num=${cdl_row}    col_num=4    value=${visibility}
    Save Excel Document    filename=${cdl_file_name}
    Close Current Excel Document
