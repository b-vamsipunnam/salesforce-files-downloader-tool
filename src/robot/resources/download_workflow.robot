*** Settings ***
Documentation       Coordinates the end-to-end Salesforce file download workflow, metadata processing, reporting, and execution summary.

Library             SeleniumLibrary
Library             OperatingSystem
Library             Collections
Library             String
Library             pabot.PabotLib
Resource            configuration.robot
Resource            salesforce_api.robot
Resource            excel_operations.robot
Resource            download_operations.robot


*** Keywords ***
Download Files Using Content Document IDs
    [Documentation]     Coordinates the complete Salesforce file download process. Reads ContentDocument IDs from Excel, initializes Salesforce API and browser sessions, retrieves metadata in batches, downloads and validates each file,
    ...    generates optional Data Loader workbooks, records failed IDs, performs cleanup, and reports the final execution result.
    [Arguments]
    ...    ${input_excel_path}
    ...    ${sheet_name}
    ...    ${GENERATE_CONTENT_VERSION_FILE}
    ...    ${GENERATE_CONTENT_DOCUMENT_LINK_FILE}

    Set Test Variable    ${GENERATE_CONTENT_VERSION_FILE}
    Set Test Variable    ${GENERATE_CONTENT_DOCUMENT_LINK_FILE}
    ${content_ids}=    Create List
    ${successful_content_ids}=    Create List
    ${failed_content_ids}=    Create List
    ${unique_failed_content_ids}=    Create List
    ${total_records}=    Set Variable    0
    ${successful_count}=    Set Variable    0
    ${failed_count}=    Set Variable    0
    ${output_directory}=    Set Variable    ${NONE}
    ${download_directory}=    Set Variable    ${NONE}
    ${current_content_id}=    Set Variable    ${NONE}
    ${unexpected_error}=    Set Variable    ${NONE}
    ${cv_file_name}=    Set Variable    ${NONE}
    ${cdl_file_name}=    Set Variable    ${NONE}
    Set Test Variable    ${successful_content_ids}
    Set Test Variable    ${failed_content_ids}
    Set Test Variable    ${total_records}
    TRY
        @{content_ids}=    Read Content IDs From Excel Sheet
        ...    ${input_excel_path}
        ...    ${sheet_name}
        ${total_records}=    Get Length    ${content_ids}
        Set Test Variable    ${total_records}
        IF    ${total_records} == 0
            Log To Console
            ...    No ContentDocumentIds found. Skipping download and Data Loader file generation.
        ELSE
            ${output_directory}=    Initialize Output Directory
            ${output_directory}=    Normalize Path    ${output_directory}
            Set Test Variable    ${output_directory}
            ${cv_row}=    Set Variable    2
            ${cdl_row}=    Set Variable    2
            IF    '${GENERATE_CONTENT_VERSION_FILE.lower()}' == 'yes'
                ${cv_row}    ${cv_file_name}=    Create ContentVersion Excel File
                ...    ${output_directory}
                Set Test Variable    ${cv_file_name}
            END
            IF    '${GENERATE_CONTENT_DOCUMENT_LINK_FILE.lower()}' == 'yes'
                ${cdl_row}    ${cdl_file_name}=    Create ContentDocumentLink Excel File
                ...    ${output_directory}
                Set Test Variable    ${cdl_file_name}
            END
            ${download_directory}=    Initialize Download Directory
            ${download_directory}=    Normalize Path    ${download_directory}
            Set Test Variable    ${download_directory}
            ${previous_level}=    Set Log Level    NONE
            TRY
                ${session_alias}=    Initialize Salesforce Session
                ${login_url}=    Get Salesforce Login Info
                Configure Browser
                ...    ${download_directory}
                ...    ${login_url}
                ...    ${org_domain}
            FINALLY
                Set Log Level    ${previous_level}
            END
            ${content_doc_map}=    Get ContentDocument Metadata Map
            ...    ${content_ids}
            ...    ${METADATA_BATCH_SIZE}
            IF    '${GENERATE_CONTENT_DOCUMENT_LINK_FILE.lower()}' == 'yes'
                ${cdl_map}=    Get ContentDocumentLink Metadata Map
                ...    ${content_ids}
                ...    ${METADATA_BATCH_SIZE}
            ELSE
                ${cdl_map}=    Create Dictionary
            END
            ${record_number}=    Set Variable    0
            FOR    ${id_value}    IN    @{content_ids}
                ${record_number}=    Evaluate    ${record_number} + 1
                ${content_id}=    Strip String    ${id_value}
                ${current_content_id}=    Set Variable    ${content_id}
                ${is_valid}=    Is Valid ContentDocument ID    ${content_id}
                IF    not ${is_valid}
                    Log To Console
                    ...    Invalid ContentDocumentId format: ${content_id}
                    Append To List
                    ...    ${failed_content_ids}
                    ...    ${content_id}
                    ${current_content_id}=    Set Variable    ${NONE}
                    CONTINUE
                END
                ${content_doc}=    Get From Dictionary
                ...    ${content_doc_map}
                ...    ${content_id}
                ...    default=${NONE}

                IF    '${GENERATE_CONTENT_DOCUMENT_LINK_FILE.lower()}' == 'yes'
                    ${content_links}=    Get From Dictionary
                    ...    ${cdl_map}
                    ...    ${content_id}
                    ...    default=${NONE}
                ELSE
                    ${content_links}=    Create List
                END
                IF    $content_doc is None
                    Log To Console
                    ...    FAILED: ${content_id} - ContentDocument metadata not found
                    Append To List
                    ...    ${failed_content_ids}
                    ...    ${content_id}
                ELSE IF    '${GENERATE_CONTENT_DOCUMENT_LINK_FILE.lower()}' == 'yes' and $content_links is None
                    Log To Console
                    ...    FAILED: ${content_id} - ContentDocumentLink metadata not found
                    Append To List
                    ...    ${failed_content_ids}
                    ...    ${content_id}
                ELSE
                    ${download_status}=    Process ContentDocument Download
                    ...    ${content_id}
                    ...    ${content_doc}
                    ...    ${content_links}
                    ...    ${record_number}
                    ...    ${cv_row}
                    ...    ${cdl_row}
                    ...    ${download_directory}

                    IF    '${download_status}' == 'PASS'
                        IF    '${GENERATE_CONTENT_VERSION_FILE.lower()}' == 'yes'
                            ${cv_row}=    Evaluate    ${cv_row} + 1
                        END
                        IF    '${GENERATE_CONTENT_DOCUMENT_LINK_FILE.lower()}' == 'yes'
                            ${link_count}=    Get Length    ${content_links}
                            ${cdl_row}=    Evaluate
                            ...    ${cdl_row} + ${link_count}
                        END
                    END
                END
                ${current_content_id}=    Set Variable    ${NONE}
            END
        END
    EXCEPT    AS    ${error}
        ${unexpected_error}=    Set Variable    ${error}
        IF    $current_content_id is not None
            Append To List
            ...    ${failed_content_ids}
            ...    ${current_content_id}
        END
        Log To Console
        ...    UNEXPECTED ERROR: ${unexpected_error}
    FINALLY
        Run Keyword And Ignore Error    Close All Excel Documents
        Run Keyword And Ignore Error    Close All Browsers
        IF    $download_directory is not None
            ${download_directory_exists}=    Run Keyword And Return Status
            ...    Directory Should Exist
            ...    ${download_directory}
            IF    ${download_directory_exists}
                Run Keyword And Ignore Error
                ...    Cleanup Download Directory    ${download_directory}
            END
        END
        ${unique_failed_content_ids}=    Remove Duplicates
        ...    ${failed_content_ids}
        ${failed_count}=    Get Length
        ...    ${unique_failed_content_ids}
        ${successful_count}=    Get Length
        ...    ${successful_content_ids}
        IF    ${successful_count} == 0
            Remove Empty Import Files
            ...    ${cv_file_name}
            ...    ${cdl_file_name}
        END
        IF    $output_directory is not None and ${failed_count} > 0
            ${report_status}    ${report_message}=    Run Keyword And Ignore Error
            ...    Write Failed ContentDocument IDs To Excel
            ...    ${unique_failed_content_ids}
            ...    ${output_directory}

            IF    '${report_status}' == 'FAIL'
                Log To Console
                ...    WARNING: Failed-ID report could not be created: ${report_message}
            END
        END
        Log    ${successful_content_ids}
        Log    ${unique_failed_content_ids}
        Log To Console
        ...    Download summary: ${successful_count} successful, ${failed_count} failed, ${total_records} total.
    END
    IF    $unexpected_error is not None
        Fail
        ...    Download processing stopped because of an unexpected error: ${unexpected_error}
    END
    IF    ${failed_count} > 0
        Fail
        ...    ${failed_count} of ${total_records} ContentDocument downloads failed. Review the failed-ID Excel file in ${output_directory}.
    END

Process ContentDocument Download
    [Documentation]     Prepares and processes one ContentDocument download. Extracts the file metadata, creates a safe local filename and ContentDocument-specific folder, builds the Salesforce Shepherd download URL, and delegates the download and validation operations.
    [Arguments]
    ...    ${content_id}
    ...    ${content_doc}
    ...    ${content_links}
    ...    ${record_number}
    ...    ${cv_row}
    ...    ${cdl_row}
    ...    ${download_directory}
    Set Test Variable    ${content_doc_id}    ${content_doc}[Id]
    Set Test Variable    ${file_title}    ${content_doc}[Title]
    Set Test Variable    ${file_extension}    ${content_doc}[FileExtension]
    Set Test Variable    ${content_version_id}    ${content_doc}[LatestPublishedVersionId]
    Set Test Variable    ${expected_file_size}    ${content_doc}[ContentSize]
    Set Test Variable    ${description}    ${content_doc}[Description]
    ${safe_file_title}=    Sanitize Filename    ${file_title}
    Set Test Variable    ${safe_file_title}
    ${file_name}=    Set Variable    ${safe_file_title}
    ${has_extension}=    Evaluate    str($file_extension).strip() not in ['', 'None', 'none', 'NULL', 'null']
    IF    ${has_extension}
        ${file_name}=    Catenate    SEPARATOR=.    ${safe_file_title}    ${file_extension}
    END
    Set Test Variable    ${file_name}
    ${download_url}=    Build ContentDocument Download URL    ${org_domain}    ${content_doc_id}
    Set Test Variable    ${download_url}    ${download_url}
    ${content_id_folder}=    Create ContentDocument ID Folder    ${content_id}    ${download_directory}
    Set Test Variable    ${content_id_folder}
    ${download_result}=    Download And Validate Content File
    ...    ${content_id}
    ...    ${download_url}
    ...    ${content_links}
    ...    ${cv_row}
    ...    ${cdl_row}
    ...    ${download_directory}
    ...    ${file_name}
    ...    ${expected_file_size}
    ...    ${safe_file_title}
    ...    ${cv_file_name}
    ...    ${cdl_file_name}
    ...    ${file_title}
    ...    ${failed_content_ids}
    ...    ${content_id_folder}
    ...    ${GENERATE_CONTENT_VERSION_FILE}
    ...    ${GENERATE_CONTENT_DOCUMENT_LINK_FILE}
    ...    ${successful_content_ids}
    Log To Console    Completed Downloading the record ${record_number} of ${total_records}\n
    RETURN    ${download_result}
