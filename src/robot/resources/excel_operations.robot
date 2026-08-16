*** Settings ***
Documentation       Reads ContentDocument IDs and creates, updates, and manages Excel files used for migration and failure reporting.

Library             OperatingSystem
Library             Collections
Library             String
Library             ../libraries/ExcelLibrary.py
Library             ../libraries/SalesforceSupport.py
Resource            configuration.robot


*** Keywords ***
Read Content IDs From Excel Sheet
    [Documentation]     Reads ContentDocument IDs from the first column of the supplied Excel sheet. Removes an optional ContentDocumentId header, ignores blank values, trims whitespace, converts valid 15-character IDs to 18 characters, removes duplicates, and returns the resulting list.
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
        ${canonical_id}=    Canonicalize Content Document Id    ${id_value}
        Append To List    ${content_ids}    ${canonical_id}
    END
    ${content_ids}=    Remove Duplicates    ${content_ids}
    RETURN    ${content_ids}

Create ContentVersion Excel File
    [Documentation]     Creates a ContentVersion Data Loader workbook in the supplied output directory, writes the required import headers, and returns the first available data row and generated workbook path.
    [Arguments]    ${download_directory}
    ${proper_test_name}=    Sanitize Local Filename    ${TEST NAME}    max_length=80
    ${cv_file_name}=    Set Variable    ${download_directory}${/}${proper_test_name}_ContentVersion_Import.xlsx
    Create Excel Document    doc_id=${cv_file_name}
    Write Excel Cell    row_num=1    col_num=1    value=Title
    Write Excel Cell    row_num=1    col_num=2    value=VersionData
    Write Excel Cell    row_num=1    col_num=3    value=PathOnClient
    Save Excel Document
    Close Current Excel Document
    ${first_data_row}=    Set Variable    2
    RETURN    ${first_data_row}    ${cv_file_name}

Create ContentDocumentLink Excel File
    [Documentation]     Creates a ContentDocumentLink Data Loader workbook in the supplied output directory, writes the required import headers, and returns the first available data row and generated workbook path.
    [Arguments]    ${download_directory}
    ${proper_test_name}=    Sanitize Local Filename    ${TEST NAME}    max_length=80
    ${cdl_file_name}=    Set Variable    ${download_directory}${/}${proper_test_name}_ContentDocumentLink_Import.xlsx
    Create Excel Document    doc_id=${cdl_file_name}
    Write Excel Cell    row_num=1    col_num=1    value=ContentDocumentId
    Write Excel Cell    row_num=1    col_num=2    value=LinkedEntityID
    Write Excel Cell    row_num=1    col_num=3    value=ShareType
    Write Excel Cell    row_num=1    col_num=4    value=Visibility
    Save Excel Document
    Close Current Excel Document
    ${first_data_row}=    Set Variable    2
    RETURN    ${first_data_row}    ${cdl_file_name}

Write Failed ContentDocument IDs To Excel
    [Documentation]     Creates a test-specific failed-ID workbook in the supplied output directory when one or more ContentDocument downloads have failed.
    [Arguments]    ${failure_records}    ${output_directory}
    ${safe_test_name}=    Sanitize Local Filename    ${TEST NAME}    max_length=80
    ${excel_file}=    Set Variable    ${output_directory}${/}${safe_test_name}_FAILED_IDs.xlsx
    ${no_of_records}=    Get Length    ${failure_records}
    IF    '${no_of_records}' != '0'
        Write Failed ContentDocument IDs    ${failure_records}    ${excel_file}
    END

Remove Empty Import Files
    [Documentation]     Removes generated ContentVersion and ContentDocumentLink workbooks when no files were downloaded successfully. Ignores workbooks that were not requested or do not exist.
    [Arguments]    ${cv_file_name}    ${cdl_file_name}
    IF    $cv_file_name is not None
        ${cv_file_exists}=    Evaluate
        ...    os.path.isfile($cv_file_name)
        ...    modules=os
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
        ${cdl_file_exists}=    Evaluate
        ...    os.path.isfile($cdl_file_name)
        ...    modules=os
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
    [Documentation]     Creates an Excel workbook containing structured final failure records. ContentDocumentId remains the first column so the workbook can be reused as downloader input.
    [Arguments]    ${failure_records}    ${excel_file}
    ${uuid}=    Evaluate    __import__('uuid').uuid4().hex
    ${temp_doc_id}=    Set Variable
    ...    salesforce_downloader_tmp_${uuid}
    Create Excel Document    ${temp_doc_id}
    Write Excel Cell    row_num=1    col_num=1    value=ContentDocumentId
    Write Excel Cell    row_num=1    col_num=2    value=FailureCode
    Write Excel Cell    row_num=1    col_num=3    value=FailureMessage
    Write Excel Cell    row_num=1    col_num=4    value=AttemptCount
    ${row}=    Set Variable    2
    FOR    ${failure}    IN    @{failure_records}
        ${safe_message}=    Sanitize Spreadsheet Cell    ${failure}[FailureMessage]
        Write Excel Cell    row_num=${row}    col_num=1    value=${failure}[ContentDocumentId]
        Write Excel Cell    row_num=${row}    col_num=2    value=${failure}[FailureCode]
        Write Excel Cell    row_num=${row}    col_num=3    value=${safe_message}
        Write Excel Cell    row_num=${row}    col_num=4    value=${failure}[AttemptCount]
        ${row}=    Evaluate    ${row} + 1
    END
    Save Excel Document    filename=${excel_file}
    Close Current Excel Document
    Run Keyword And Ignore Error    Remove File    ${temp_doc_id}

Write Sanitized Migration Rows Atomically
    [Documentation]     Sanitizes the Salesforce title against spreadsheet formula injection, then stages and commits the requested ContentVersion and ContentDocumentLink rows atomically.
    [Arguments]
    ...    ${cv_file_name}
    ...    ${cv_row}
    ...    ${file_title}
    ...    ${version_data_path}
    ...    ${cdl_file_name}
    ...    ${cdl_row}
    ...    ${content_links}
    ...    ${write_content_version}=${TRUE}
    ...    ${write_content_document_links}=${TRUE}
    ${safe_file_title}=    Sanitize Spreadsheet Cell    ${file_title}
    Write Migration Rows Atomically
    ...    ${cv_file_name}
    ...    ${cv_row}
    ...    ${safe_file_title}
    ...    ${version_data_path}
    ...    ${cdl_file_name}
    ...    ${cdl_row}
    ...    ${content_links}
    ...    write_content_version=${write_content_version}
    ...    write_content_document_links=${write_content_document_links}
