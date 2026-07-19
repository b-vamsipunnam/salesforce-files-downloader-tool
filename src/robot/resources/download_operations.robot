*** Settings ***
Documentation       Handles browser configuration, file downloads, validation, file movement, directory management, and download failure processing.

Library             SeleniumLibrary
Library             OperatingSystem
Library             Collections
Library             String
Library             ../libraries/WebdriverManager.py
Library             ../libraries/SalesforceSupport.py
Resource            configuration.robot
Resource            excel_operations.robot


*** Keywords ***
Initialize Output Directory
    [Documentation]     Creates and returns a unique output directory for the current test. The directory stores generated ContentVersion, ContentDocumentLink, and failed-ID Excel files without conflicting with parallel executions.
    ${uuid}=    Evaluate    __import__('uuid').uuid4().hex
    ${safe_test_name}=    Replace String    ${TEST NAME}    ${SPACE}    _
    ${output_directory}=    Set Variable    ${OUTPUT_FOLDER}/${safe_test_name}_${uuid}
    Create Directory    ${output_directory}
    Directory Should Exist    ${output_directory}
    RETURN    ${output_directory}

Initialize Download Directory
    [Documentation]     Creates and returns a unique browser download directory for the current test. The test name and a random identifier isolate downloads during parallel execution.
    ${uuid}=    Evaluate    __import__('uuid').uuid4().hex
    ${safe_test_name}=    Replace String    ${TEST NAME}    ${SPACE}    _
    ${download_directory}=    Set Variable    ${BASE_DOWNLOAD_FOLDER}/${safe_test_name}_${uuid}
    Create Directory    ${download_directory}
    Directory Should Exist    ${download_directory}
    RETURN    ${download_directory}

Configure Browser
    [Documentation]     Opens and configures a Chrome browser for Salesforce file downloads. Applies the requested download directory, authenticates through the Salesforce frontdoor URL, configures the organization domain, and optionally runs Chrome in headless mode.
    [Tags]    robot:flatten
    [Arguments]    ${download_directory}    ${login_url}    ${org_domain}    ${headless}=${True}
    Configure Chrome Browser    ${download_directory}    ${login_url}    ${org_domain}    headless=${headless}

Build ContentDocument Download URL
    [Documentation]     Builds and returns the Salesforce Shepherd download URL for the supplied organization domain and ContentDocument ID.
    [Arguments]    ${org_domain}    ${document_id}
    ${download_url}=    Set Variable
    ...    https://${org_domain}.my.salesforce.com/sfc/servlet.shepherd/document/download/${document_id}
    RETURN    ${download_url}

Create ContentDocument ID Folder
    [Documentation]     Creates and returns a dedicated folder for the supplied ContentDocument ID inside the active download directory.
    [Arguments]    ${content_id}    ${download_directory}
    ${content_id_folder}=    Set Variable    ${download_directory}${/}${content_id}
    Create Directory    ${content_id_folder}
    Directory Should Exist    ${content_id_folder}
    RETURN    ${content_id_folder}

Sanitize Filename
    [Documentation]     Converts a Salesforce file title into a valid local filename by replacing operating-system-restricted characters with underscores and removing surrounding whitespace.
    [Arguments]    ${name}
    ${safe}=    Evaluate    re.sub(r'[\\\\/:*?"<>|]', '_', str($name)).strip()    modules=re
    RETURN    ${safe}

Download And Validate Content File
    [Documentation]     Starts a Salesforce file download through the browser and validates its completion, filename, and expected size. Selects the correct file when multiple files are detected, delegates final movement and Excel updates, and records failures when any validation step fails.
    [Arguments]
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
    Cleanup Download Directory    ${download_directory}
    Log To Console    Starting download: ${file_name} and expected size: ${expected_file_size} bytes
    ${is_url_success}=    Run Keyword And Return Status    Go To    ${download_url}
    IF    not ${is_url_success}
        ${status}=    Handle Download Failure    ${content_id}    Browser navigation to download URL failed
        ...    ${failed_content_ids}    ${content_id_folder}    ${download_directory}
        RETURN    ${status}
    END
    ${is_file_appeared}=    Run Keyword And Return Status
    ...    Wait Until Download File Appears
    ...    ${DOWNLOAD_APPEAR_TIMEOUT}
    ...    ${download_directory}
    IF    not ${is_file_appeared}
        ${status}=    Handle Download Failure    ${content_id}    Download file did not appear within timeout
        ...    ${failed_content_ids}    ${content_id_folder}    ${download_directory}
        RETURN    ${status}
    END
    ${download_dir_path}=    Normalize Path    ${download_directory}
    Directory Should Exist    ${download_dir_path}
    ${files_in_download_dir}=    List Files In Directory    ${download_directory}
    ${recent_file_count}=    Get Length    ${files_in_download_dir}
    IF    '${recent_file_count}' == '0'
        ${status}=    Handle Download Failure    ${content_id}    Download directory is empty after download trigger
        ...    ${failed_content_ids}    ${content_id_folder}    ${download_directory}
        RETURN    ${status}
    END
    ${is_download_proper}=    Run Keyword And Return Status
    ...    Wait Until File Download Completes
    ...    ${download_directory}
    IF    not ${is_download_proper}
        ${status}=    Handle Download Failure    ${content_id}    Download did not complete within timeout
        ...    ${failed_content_ids}    ${content_id_folder}    ${download_directory}
        RETURN    ${status}
    END
    ${recent_files}=    List Files In Directory    ${download_directory}
    ${recent_file_count}=    Get Length    ${recent_files}
    IF    ${recent_file_count} == 0
        ${status}=    Handle Download Failure    ${content_id}    No downloaded file found after completion wait
        ...    ${failed_content_ids}    ${content_id_folder}    ${download_directory}
        RETURN    ${status}
    END
    IF    ${recent_file_count} > 1
        Log    WARNING: Multiple files detected in download directory: ${recent_files}
        ${matching_size_files}=    Create List
        FOR    ${file}    IN    @{recent_files}
            ${file_size}=    Get File Size    ${download_directory}${/}${file}
            IF    ${file_size} == ${expected_file_size}
                Append To List    ${matching_size_files}    ${file}
            END
        END
        ${matching_count}=    Get Length    ${matching_size_files}
        IF    ${matching_count} == 0
            ${status}=    Handle Download Failure    ${content_id}    No downloaded file matched expected file size
            ...    ${failed_content_ids}    ${content_id_folder}    ${download_directory}
            RETURN    ${status}
        END
        ${latest_filename}=    Evaluate
        ...    max($matching_size_files, key=lambda f: os.path.getmtime(os.path.join($download_directory, f)))
        ...    modules=os
        Set Test Variable    ${latest_filename}
    END
    IF    ${recent_file_count} == 1
        Set Test Variable    ${latest_filename}    ${recent_files}[0]
    END
    ${downloaded_size}=    Get File Size    ${download_directory}${/}${latest_filename}
    IF    ${downloaded_size} != ${expected_file_size}
        ${status}=    Handle Download Failure
        ...    ${content_id}
        ...    Downloaded file size does not match expected ContentSize
        ...    ${failed_content_ids}    ${content_id_folder}    ${download_directory}
        RETURN    ${status}
    END
    ${is_name_match}=    Run Keyword And Return Status    Should Start With    ${latest_filename}    ${safe_file_title}
    IF    not ${is_name_match}
        Log
        ...    WARNING: Downloaded filename does not match the sanitized expected title. Expected: ${safe_file_title}, Actual: ${latest_filename}, Expected size: ${expected_file_size}, Actual size: ${downloaded_size}
    END
    ${validation_status}=    Validate And Move Downloaded File
    ...    ${latest_filename}
    ...    ${content_id}
    ...    ${content_links}
    ...    ${FILE_STABILITY_MAX_CHECKS}
    ...    ${cv_row}
    ...    ${cdl_row}
    ...    ${cv_file_name}
    ...    ${cdl_file_name}
    ...    ${file_title}
    ...    ${failed_content_ids}
    ...    ${content_id_folder}
    ...    ${download_directory}
    ...    ${file_name}
    ...    ${GENERATE_CONTENT_VERSION_FILE}
    ...    ${GENERATE_CONTENT_DOCUMENT_LINK_FILE}
    ...    ${expected_file_size}
    ...    ${successful_content_ids}
    RETURN    ${validation_status}

Download Directory Should Contain Completed File
    [Documentation]     Verifies that the active download directory contains at least one completed file. Files ending with configured temporary download extensions are excluded.
    [Arguments]    ${download_directory}
    ${files}=    List Files In Directory    ${download_directory}
    ${valid_files}=    Create List
    FOR    ${file}    IN    @{files}
        ${lower_file}=    Convert To Lower Case    ${file}
        ${is_temp}=    Evaluate
        ...    $lower_file.endswith(tuple($TEMP_FILE_SUFFIXES))
        IF    not ${is_temp}    Append To List    ${valid_files}    ${file}
    END
    ${count}=    Get Length    ${valid_files}
    Should Be True    ${count} > 0
    ...    msg=No completed download found in ${download_directory}. Files present: ${files}

Wait Until Download File Appears
    [Documentation]     Waits until a completed, non-temporary file appears in the active download directory or fails when the supplied timeout expires.
    [Arguments]    ${timeout}    ${download_directory}
    Wait Until Keyword Succeeds
    ...    ${timeout}
    ...    1s
    ...    Download Directory Should Contain Completed File
    ...    ${download_directory}

Wait Until File Download Completes
    [Documentation]     Polls the active download directory until a completed file is detected. Continues checking while only temporary or partial files are present and fails when the configured completion timeout expires.
    [Arguments]    ${download_directory}
    Set Test Variable    ${is_filename_proper}    ${FALSE}
    WHILE    not ${is_filename_proper}
    ...    limit=${DOWNLOAD_COMPLETE_TIMEOUT}
    ...    on_limit=FAIL
    ...    on_limit_message=Download did not complete within ${DOWNLOAD_COMPLETE_TIMEOUT}
        ${recent_files}=    List Files In Directory    ${download_directory}
        ${file_count}=    Get Length    ${recent_files}
        IF    ${file_count} == 0
            Sleep    0.5s
            CONTINUE
        END
        Find Completed Download File    ${recent_files}
        IF    not ${is_filename_proper}    Sleep    0.5s
    END

Find Completed Download File
    [Documentation]     Inspects the supplied filenames for a completed download. Stores the first non-temporary filename as the latest downloaded file and updates the download-completion status.
    [Arguments]    ${recent_files}
    Set Test Variable    ${is_filename_proper}    ${FALSE}
    FOR    ${file}    IN    @{recent_files}
        ${lower_file}=    Convert To Lower Case    ${file}
        ${is_temp}=    Evaluate
        ...    $lower_file.endswith(tuple($TEMP_FILE_SUFFIXES))

        IF    not ${is_temp}
            Set Test Variable    ${latest_filename}    ${file}
            Set Test Variable    ${is_filename_proper}    ${TRUE}
            RETURN
        END
    END

Handle Download Failure
    [Documentation]     Records a failed ContentDocument ID, removes its ContentDocument-specific folder, cleans remaining files from the active download directory, logs the failure reason, and returns FAIL.
    [Arguments]    ${content_id}    ${reason}
    ...    ${failed_content_ids}    ${content_id_folder}    ${download_directory}
    Append To List    ${failed_content_ids}    ${content_id}
    Run Keyword And Ignore Error
    ...    Remove Directory
    ...    ${content_id_folder}
    ...    recursive=True
    Run Keyword And Ignore Error
    ...    Cleanup Download Directory    ${download_directory}
    IF    '${reason}' != '${EMPTY}'
        Log To Console    FAILED: ${content_id} - ${reason}
    ELSE
        Log To Console    FAILED: ${content_id}
    END
    RETURN    FAIL

Move Downloaded File With Retry
    [Documentation]     Moves a downloaded file from the source path to the destination path. Retries the operation until it succeeds or the configured timeout expires, allowing temporary Windows file locks to clear.
    [Arguments]    ${src}    ${dst}
    Wait Until Keyword Succeeds
    ...    ${FILE_MOVE_TIMEOUT}
    ...    ${FILE_MOVE_RETRY_INTERVAL}
    ...    Move File
    ...    ${src}
    ...    ${dst}

Validate And Move Downloaded File
    [Documentation]     Confirms that the downloaded file exists, has stabilized, and matches the expected Salesforce ContentSize before moving it into its ContentDocument-specific folder. On success, writes the requested ContentVersion and ContentDocumentLink rows and records the ID as successful. On failure, removes incomplete artifacts and records the ID as failed.
    [Arguments]
    ...    ${downloaded_filename}
    ...    ${content_id}
    ...    ${content_links}
    ...    ${timeout}
    ...    ${cv_row}
    ...    ${cdl_row}
    ...    ${cv_file_name}
    ...    ${cdl_file_name}
    ...    ${file_title}
    ...    ${failed_content_ids}
    ...    ${content_id_folder}
    ...    ${download_directory}
    ...    ${file_name}
    ...    ${GENERATE_CONTENT_VERSION_FILE}
    ...    ${GENERATE_CONTENT_DOCUMENT_LINK_FILE}
    ...    ${expected_file_size}
    ...    ${successful_content_ids}
    ${src}=    Set Variable    ${download_directory}${/}${downloaded_filename}
    ${dst}=    Set Variable    ${content_id_folder}${/}${file_name}
    ${is_source_file_exists}=    Run Keyword And Return Status    File Should Exist    ${src}
    IF    not ${is_source_file_exists}
        ${status}=    Handle Download Failure    ${content_id}    Downloaded source file missing before move
        ...    ${failed_content_ids}    ${content_id_folder}    ${download_directory}
        RETURN    ${status}
    END
    ${previous_file_size}=    Set Variable    -1
    ${is_size_stable}=    Set Variable    ${FALSE}
    FOR    ${i}    IN RANGE    ${timeout}
        ${current_file_size}=    Get File Size    ${src}
        IF    ${current_file_size} == ${previous_file_size}
            ${is_size_stable}=    Set Variable    ${TRUE}
            BREAK
        END
        ${previous_file_size}=    Set Variable    ${current_file_size}
        Sleep    ${FILE_STABILITY_INTERVAL}
    END
    IF    not ${is_size_stable}
        ${status}=    Handle Download Failure
        ...    ${content_id}
        ...    Downloaded file size did not stabilize
        ...    ${failed_content_ids}    ${content_id_folder}    ${download_directory}
        RETURN    ${status}
    END
    ${is_source_file_exists}=    Run Keyword And Return Status    File Should Exist    ${src}
    IF    not ${is_source_file_exists}
        ${status}=    Handle Download Failure    ${content_id}    Downloaded source file disappeared before move
        ...    ${failed_content_ids}    ${content_id_folder}    ${download_directory}
        RETURN    ${status}
    END
    ${is_file_moved}=    Run Keyword And Return Status
    ...    Move Downloaded File With Retry
    ...    ${src}
    ...    ${dst}
    IF    not ${is_file_moved}
        ${status}=    Handle Download Failure
        ...    ${content_id}
        ...    Downloaded file remained locked and could not be moved within ${FILE_MOVE_TIMEOUT}
        ...    ${failed_content_ids}    ${content_id_folder}    ${download_directory}
        RETURN    ${status}
    END
    ${target_file_exists}=    Run Keyword And Return Status
    ...    File Should Exist
    ...    ${dst}
    IF    ${target_file_exists}
        ${actual_file_size}=    Get File Size    ${dst}
    ELSE
        ${actual_file_size}=    Set Variable    ${NONE}
    END
    IF    ${target_file_exists}
        ${is_file_size_matching}=    Evaluate    int($actual_file_size) == int($expected_file_size)
    ELSE
        ${is_file_size_matching}=    Set Variable    ${FALSE}
    END
    IF    ${target_file_exists} and ${is_file_size_matching}
        IF    '${GENERATE_CONTENT_VERSION_FILE.lower()}' == 'yes'
            Write ContentVersion Row
            ...    ${cv_row}
            ...    ${dst}
            ...    ${cv_file_name}
            ...    ${file_title}
        END
        IF    '${GENERATE_CONTENT_DOCUMENT_LINK_FILE.lower()}' == 'yes'
            ${current_cdl_row}=    Set Variable    ${cdl_row}
            FOR    ${content_link}    IN    @{content_links}
                Write ContentDocumentLink Row
                ...    ${current_cdl_row}
                ...    ${content_link}
                ...    ${cdl_file_name}
                ${current_cdl_row}=    Evaluate
                ...    ${current_cdl_row} + 1
            END
        END
        Append To List    ${successful_content_ids}    ${content_id}
        Log To Console
        ...    SUCCESS: ${file_name} downloaded and moved to ${content_id}
        ${source_still_exists}=    Run Keyword And Return Status
        ...    File Should Exist
        ...    ${src}
        IF    ${source_still_exists}
            Run Keyword And Ignore Error    Remove File    ${src}
        END
        Cleanup Download Directory    ${download_directory}
        RETURN    PASS
    ELSE
        ${source_still_exists}=    Run Keyword And Return Status    File Should Exist    ${src}
        IF    ${source_still_exists}
            Run Keyword And Ignore Error    Remove File    ${src}
        END
        ${status}=    Handle Download Failure
        ...    ${content_id}
        ...    Moved file missing or final file size validation failed
        ...    ${failed_content_ids}    ${content_id_folder}    ${download_directory}
        RETURN    ${status}
    END

Cleanup Download Directory
    [Documentation]     Removes files remaining in the active browser download directory while preserving ContentDocument-specific subfolders containing successfully downloaded files.
    [Arguments]    ${download_directory}
    ${download_dir_path}=    Normalize Path    ${download_directory}
    Directory Should Exist    ${download_dir_path}
    ${list_files}=    Evaluate
    ...    [f for f in os.listdir(r'${download_dir_path}') if os.path.isfile(os.path.join(r'${download_dir_path}', f))]
    ...    modules=os
    ${file_count}=    Evaluate    len($list_files)    modules=os
    Log    Found ${file_count} files to delete.
    FOR    ${file}    IN    @{list_files}
        ${full_path}=    Evaluate    os.path.join(r'${download_dir_path}', $file)    modules=os
        ${keyword_status}=    Run Keyword And Ignore Error    Evaluate    os.remove($full_path)    modules=os
        ${is_file_deleted}=    Set Variable    ${keyword_status}[0]
        IF    '${is_file_deleted}' == 'PASS'    Log    DELETED : ${file}
        IF    '${is_file_deleted}' == 'FAIL'    Remove File    ${full_path}
    END
