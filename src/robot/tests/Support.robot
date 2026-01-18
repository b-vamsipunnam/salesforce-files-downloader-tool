*** Settings ***
Documentation                              Support For Bulk Salesforce Files Downloader
Library                                    SeleniumLibrary
Library                                    OperatingSystem
Library                                    Collections
Library                                    String
Library                                    DateTime
Library                                    ExcelLibrary
Library                                    pabot.PabotLib
Library                                    Process
Library                                    RequestsLibrary
Library                                    BuiltIn
Library                                    json
Library                                    urllib.parse
Library                                    ../library/SalesforceSupport.py
Library                                    ../library/WebdriverManager.py

*** Variables ***
@{TEMP_FILE_MARKERS}                       .crdownload    .tmp    .part    unconfirmed    downloading
${org_info_file}                           org_info.json
${input_folder}                            ${EXECDIR}${/}input
${base_download_folder}                    ${EXECDIR}${/}downloads
${output_folder}                           ${EXECDIR}${/}output

*** Keywords ***
Init Salesforce Session
    ${uuid}=                               Evaluate                         __import__('uuid').uuid4().hex
    ${session_alias}=                      Set Variable                     salesforce_${uuid}
    Set Test Variable                      ${session_alias}
    ${json_text}=                          OperatingSystem.Get File         ${org_info_file}                            encoding=UTF-8-sig
    ${org_dict}=                           Evaluate                         json.loads(r"""${json_text}""")             modules=json
    LOG                                    ${org_dict}
    ${token}=                              Set Variable                     ${org_dict['result']['accessToken']}
    ${instance}=                           Set Variable                     ${org_dict['result']['instanceUrl']}
    ${apiVersion}=                         Set Variable                     ${org_dict['result']['apiVersion']}
    ${orgalias}=                           Set Variable                     ${org_dict['result']['alias']}
    Set Test Variable                      ${apiVersion}
    ${headers}=                            Create Dictionary
    ...                                    Authorization=Bearer ${token}
    ...                                    Content-Type=application/json
    Create Session                         ${session_alias}                 ${instance}                                 headers=${headers}
    RETURN                                 ${session_alias}

Get Salesforce Login Info
    ${json_text}=                          OperatingSystem.Get File         ${org_info_file}                            encoding=UTF-8-sig
    ${org_dict}=                           Evaluate                         json.loads(r"""${json_text}""")             modules=json
    ${instance_url}=                       Set Variable                     ${org_dict['result']['instanceUrl']}
    ${access_token}=                       Set Variable                     ${org_dict['result']['accessToken']}
    ${login_url}=                          Set Variable                     ${instance_url}/secur/frontdoor.jsp?sid=${access_token}
    ${parsed}=                             Evaluate                         urllib.parse.urlparse("${login_url}")       modules=urllib.parse
    ${netloc}=                             Set Variable                     ${parsed.netloc}
    ${org_domain}=                         Replace String                   ${netloc}    .my.salesforce.com             ${EMPTY}
    Set Test Variable                      ${org_domain}
    RETURN                                 ${login_url}

Init Download Directory
    ${uuid}=                               Evaluate                         __import__('uuid').uuid4().hex
    ${safe_test_name}=                     Replace String                   ${TEST NAME}    ${SPACE}    _
    ${download_directory}=                 Set Variable                     ${base_download_folder}/${safe_test_name}_${uuid}
    Create Directory                       ${download_directory}
    Directory Should Exist                 ${download_directory}
    RETURN                                 ${download_directory}

Configure Browser
    [Arguments]                            ${download_directory}            ${login_url}                                ${org_domain}                                ${headless}=${True}
    Configure Chrome Browser               ${download_directory}            ${login_url}                                ${org_domain}                                headless=${headless}


Safe Salesforce GET
    [Arguments]                            ${session_alias}                 ${url}                                      ${params}
    ${status}    ${resp}=                  Run Keyword And Ignore Error     GET On Session                              ${session_alias}                             ${url}        params=${params}
    IF    '${status}' == 'FAIL'
           RETURN    ${None}
    END
    ${status_code}=     Set Variable       ${resp.status_code}
    IF    ${status_code} != 200
          RETURN    ${resp}
    END
    RETURN    ${resp}

Run SOQL
    [Arguments]                            ${soql}                          ${session_alias}
    ${params}=                             Create Dictionary                q=${soql}
    ${resp}=                               Safe Salesforce GET              ${session_alias}                            /services/data/v${apiVersion}/query          params=${params}
    IF    $resp == None
        RETURN    @{EMPTY}
    END
    ${json}=    Evaluate    $resp.json()
    RETURN      ${json['records']}

Get Content Document
    [Arguments]                            ${content_id}
    ${soql}=                               Set Variable                     SELECT Id, Description, Title, FileExtension, LatestPublishedVersionId, ContentSize FROM ContentDocument WHERE Id='${content_id}'
    ${records}=                            Run SOQL                         ${soql}                                     ${session_alias}
    ${records_count}                       Get Length                       ${records}
    IF    ${records_count} > 0
        RETURN    ${records}[0]
    END
    RETURN    None

Get Content LinkedEntityId
    [Arguments]                            ${content_id}
    ${soql}=                               Set Variable                     SELECT ContentDocumentId, Id, ShareType, Visibility, LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId ='${content_id}'
    ${records}=                            Run SOQL                         ${soql}                                     ${session_alias}
    ${records_count}                       Get Length                       ${records}
    IF    ${records_count} > 0
          RETURN    ${records}[0]
    END
    RETURN    None

Build ContentDocument Download URL
    [Documentation]                        Builds URL to download the latest version of a file using ContentDocument ID (069...)
    [Arguments]                            ${org_domain}                    ${documentId}
    ${download_url}=                       Set Variable                     https://${org_domain}.my.salesforce.com/sfc/servlet.shepherd/document/download/${documentId}
    RETURN                                 ${download_url}

Create Folder with name ContentDocument ID
    [Documentation]                        Create a folder with the Content document or version ID in the given path.
    [Arguments]                            ${content_id}
    ${content_id_folder}=                  Set Variable                     ${download_directory}${/}${content_id}
    Create Directory                       ${content_id_folder}
    Directory Should Exist                 ${content_id_folder}
    RETURN                                 ${content_id_folder}

Read Content IDs From Excel Sheet
    [Arguments]                            ${input_excel_path}              ${sheet_name}
    ${input_excel_path}=                   Normalize Path                   ${input_excel_path}
    Open Excel Document                    filename=${input_excel_path}     doc_id=${sheet_name}
    @{column_values}=                      Read Excel Column                1       0       0                           ${sheet_name}
    Close Current Excel Document
    Remove From List                       ${column_values}                 0
    @{content_ids}=                        Create List
    FOR    ${value}    IN    @{column_values}
           ${str value}=                   Convert To String                ${value}
           ${id value}=                    Strip String                     ${str value}
           Continue For Loop If    '${id value}' == '${EMPTY}' or '${id value}' == '${None}'
           Append To List                  ${content_ids}                   ${id value}
    END
    Close Current Excel Document
    RETURN                                 ${content_ids}

Init Output Directory
    ${uuid}=                               Evaluate                         __import__('uuid').uuid4().hex
    ${safe_test_name}=                     Replace String                   ${TEST NAME}        ${SPACE}    _
    ${download_directory}=                 Set Variable                     ${output_folder}/${safe_test_name}_${uuid}
    Create Directory                       ${download_directory}
    Directory Should Exist                 ${download_directory}
    RETURN                                 ${download_directory}

ContentVersion Excel file
    [Arguments]                            ${download_directory}
    ${uuid}=                               Evaluate                         __import__('uuid').uuid4().hex
    ${Proper_test_name}=                   Replace String                   ${TEST NAME}        ${SPACE}    _
    ${CV_File_Name}=                       Set Variable                     ${download_directory}${/}${Proper_test_name}_ContentVersion_Inputfile.xlsx
    Create Excel Document                  doc_id=CV_DOC
    Write Excel Cell                       row_num=1                        col_num=1                                   value=Title
    Write Excel Cell                       row_num=1                        col_num=2                                   value=VersionData
    Write Excel Cell                       row_num=1                        col_num=3                                   value=PathOnClient
    #Write Excel Cell                      row_num=1                        col_num=4                                   value=Description
    #Write Excel Cell                      row_num=1                        col_num=5                                   value=FirstPublishLocationId
    Save Excel Document                    filename=${CV_File_Name}
    Close Current Excel Document
    ${rowValue}=                           Set Variable    2
    RETURN                                 ${rowValue}                      ${CV_File_Name}

ContentDocumentLink Excel file
    [Arguments]                            ${download_directory}
    ${uuid}=                               Evaluate                         __import__('uuid').uuid4().hex
    ${Proper_test_name}=                   Replace String                   ${TEST NAME}        ${SPACE}    _
    ${CDL_File_Name}=                      Set Variable                     ${download_directory}${/}${Proper_test_name}_ContentDocumentLink_Inputfile.xlsx
    Create Excel Document                  doc_id=CDL_DOC
    Write Excel Cell                       row_num=1                        col_num=1                                   value=ContentDocumentId
    Write Excel Cell                       row_num=1                        col_num=2                                   value=LinkedEntityID
    Write Excel Cell                       row_num=1                        col_num=3                                   value=ShareType
    Write Excel Cell                       row_num=1                        col_num=4                                   value=Visibility
    Save Excel Document                    filename=${CDL_File_Name}
    Close Current Excel Document
    ${rowValue}=                           Set Variable    2
    RETURN                                 ${rowValue}                      ${CDL_File_Name}

Download the SFDC files using the ContentDocumentIDs
    #[Tags]                 robot:flatten
    [Arguments]                            ${input_excel_path}              ${sheet_name}
    ${output_directory}=                   Init Output Directory
    ${output_directory}=                   Normalize Path                   ${output_directory}
    Set Suite Variable                     ${output_directory}
    ${cv_row}       ${CV_File_Name}=       ContentVersion Excel file        ${output_directory}
    ${cdl_row}      ${CDL_File_Name}=      ContentDocumentLink Excel file   ${output_directory}
    Set Test Variable                      ${CV_File_Name}
    Set Test Variable                      ${CDL_File_Name}
    @{content_ids_Working}                 Create List
    @{content_ids_NotWorking}              Create List
    Set Suite Variable                     @{content_ids_Working}
    Set Suite Variable                     @{content_ids_NotWorking}
    ${session_alias}=                      Init Salesforce Session
    ${login_url}=                          Get Salesforce Login Info
    ${download_directory}=                 Init Download Directory
    ${download_directory}=                 Normalize Path                   ${download_directory}
    Set Suite Variable                     ${download_directory}
    Configure Browser                      ${download_directory}            ${login_url}                                ${org_domain}
    @{content_ids}=                        Read Content IDs From Excel Sheet                                            ${input_excel_path}                          ${sheet_name}
    ${total_records}                       Get Length                       ${content_ids}
    Set Suite Variable                     ${total_records}
    ${record_number}=                      Set Variable                     0
    FOR    ${content_id}    IN     @{content_ids}
           ${record_number}=               Evaluate                         ${record_number} + 1
           Set Suite Variable              ${content_id}                    ${content_id}
           ${content_doc}=                 Get Content Document             ${content_id}
           Log      ${content_doc}
           ${content_LinkedEntityId}=      Get Content LinkedEntityId       ${content_id}
           Log      ${content_LinkedEntityId}
           IF    ${content_doc} is None
                 Append To List	           ${content_ids_NotWorking}	    ${content_id}
           ELSE
                 Get ContentDocumentID Details and Launch the URL           ${content_doc}                              ${content_LinkedEntityId}                    ${record_number}    ${cv_row}       ${cdl_row}
                 ${cv_row}=                Evaluate                         ${cv_row} + 1
                 ${cdl_row}=               Evaluate                         ${cdl_row} + 1
           END
    END
    Log    ${content_ids_Working}
    Log    ${content_ids_NotWorking}
    @{unique_IDslist_NotWorking}=          Remove Duplicates                ${content_ids_NotWorking}
    Log FAILED ContentDocumentID details in Excelfile                       ${unique_IDslist_NotWorking}                ${output_directory}
    Close All Excel Documents


Get ContentDocumentID Details and Launch the URL
    [Arguments]                            ${content_doc}                   ${content_LinkedEntityId}                   ${record_number}                             ${cv_row}               ${cdl_row}
    Set Test Variable                      ${content_doc_id}                ${content_doc}[Id]
    Set Test Variable                      ${file_title}                    ${content_doc}[Title]
    Set Test Variable                      ${file_extension}                ${content_doc}[FileExtension]
    Set Test Variable                      ${content_version_id}            ${content_doc}[LatestPublishedVersionId]
    Set Test Variable                      ${expected_file_size}            ${content_doc}[ContentSize]
    Set Test Variable                      ${Description}                   ${content_doc}[Description]
    Set Test Variable                      ${ContentDocumentIDValue}        ${content_LinkedEntityId}[ContentDocumentId]
    Set Test Variable                      ${LinkedEntityID}                ${content_LinkedEntityId}[LinkedEntityId]
    Set Test Variable                      ${ShareType}                     ${content_LinkedEntityId}[ShareType]
    Set Test Variable                      ${Visibility}                    ${content_LinkedEntityId}[Visibility]
    Set Test Variable                      ${ContentDocumentLink_id}        ${content_LinkedEntityId}[Id]
    ${file_name}=                          Catenate    SEPARATOR=           ${file_title}       .                       ${file_extension}
    Set Suite Variable                     ${file_name}
    ${download_url}                        Build ContentDocument Download URL                                           ${org_domain}                                ${content_id}
    Set Suite Variable                     ${download_url}                  ${download_url}
    ${content_id_folder}=                  Create Folder with name ContentDocument ID                                   ${content_id}
    Set Suite Variable                     ${content_id_folder}
    Run Keyword If    '${file_extension}' == '${EMPTY}' or '${file_extension}' == '${None}'                             Set Suite Variable                           ${file_name}            ${file_title}
    ${download_result}=                    Run Keyword And Ignore Error     Download And Validate Content File          ${download_url}                              ${cv_row}               ${cdl_row}
    Set Suite Variable                     ${is_download_success}           ${download_result[0]}
    Run Keyword If    '${is_download_success}' == 'FAIL'                    Append To List	                            ${content_ids_NotWorking}	                 ${content_id}
    Log To Console                         Completed Downloading the record ${record_number} of ${total_records}\n

Download And Validate Content File
    [Arguments]                            ${download_url}                  ${cv_row}                                   ${cdl_row}
    Log To Console                         Starting download: ${file_name} and expected size: ${expected_file_size} bytes
    ${UrlResponse}=                        Run Keyword And Ignore Error     Go To                                       ${download_url}
    Set Suite Variable                     ${is_url_success}                ${UrlResponse[0]}
    #Sleep    2s
    Run Keyword If    '${is_url_success}' == 'FAIL'                         Append To List	                            ${content_ids_NotWorking}	                 ${content_id}
    ${download_dir_path}                   Normalize Path                   ${download_directory}
    Directory Should Exist                                                  ${download_dir_path}
    ${files_in_download_dir}=              List Directory                   ${download_directory}                       pattern=*.*
    ${file_count}                          Get Length                       ${files_in_download_dir}
    Run Keyword If    '${file_count}' == '0'                                Remove Content Folder And Temp Files
    @{MatchingFileNames}                   Create List
    @{NotMatchingFileNames}                Create List
    FOR    ${existingfilename}    IN    @{files_in_download_dir}
           Set Suite Variable              ${temp_filename}                 ${existingfilename}
           ${IsDownloadProper}=            Run Keyword And Return Status    Wait Until File Download Completes
           Run Keyword If    '${IsDownloadProper}' == 'False'               Remove Content Folder And Temp Files
           ${RecentFile}=                  List Directory                   ${download_directory}                       pattern=*.*
           ${RecentFile_count}             Get Length                       ${RecentFile}
           Run Keyword If    '${RecentFile_count}' != '0'                   Set Suite Variable                          ${latest_filename}                           ${RecentFile}[0]
           ${IsNameMatch}=                 Run Keyword And Return Status    Should Contain                              ${latest_filename}                           ${file_title}
           Run Keyword If    '${IsNameMatch}' == 'True'                     Append To List                              ${MatchingFileNames}                         ${latest_filename}
           Run Keyword If    '${IsNameMatch}' == 'False'                    Append To List                              ${NotMatchingFileNames}                      ${latest_filename}
    END
    FOR    ${FinalMatchingFilename}    IN    @{MatchingFileNames}
           Set Suite Variable              ${downloaded_filename}           ${FinalMatchingFilename}
           ${IsNameMatch}=                 Run Keyword And Return Status    Should Contain                              ${downloaded_filename}                       ${file_title}
           Run Keyword If    '${IsNameMatch}' == 'True'                     Downloaded File name is a Match             500                                          ${cv_row}       ${cdl_row}
    END
    FOR    ${NotMatchingFilename}    IN    @{NotMatchingFileNames}
           Set Suite Variable              ${downloaded_filename_notmatched}                                            ${NotMatchingFilename}
           ${IsNameMatch}=                 Run Keyword And Return Status    Should Contain                              ${downloaded_filename_notmatched}            ${file_title}
           Run Keyword If    '${IsNameMatch}' == 'False'                    Remove Content Folder And Temp Files
    END

Wait Until File Download Completes
    ${IsTempfilesExist}=                   Run Keyword And Return Status    Should Not Contain Any                      ${temp_filename}                             @{TEMP_FILE_MARKERS}
    ${StatusCheck}                         Set Variable                     ${IsTempfilesExist}
    WHILE    '${StatusCheck}' == '${FALSE}'    limit=60s
              ${RecentFile}=               List Directory                   ${download_directory}                       pattern=*.*
              ${file_count}                Get Length                       ${RecentFile}
              Run Keyword If    '${file_count}' == '0'                      Run Keyword And Ignore Error                Remove Directory                             ${content_id_folder}
              Run Keyword If    '${file_count}' != '0'                      Check File is Downloaded                    ${RecentFile}
              ${StatusCheck}               Get Variable Value               ${IsFileNameProper}
    END

Check File is Downloaded
    [Arguments]                            ${RecentFile}
    Set Suite Variable                     ${latest_filename}               ${RecentFile}[0]
    ${IsFileNameProper}=                   Run Keyword And Return Status    Should Not Contain Any                      ${latest_filename}                           @{TEMP_FILE_MARKERS}
    Set Suite Variable                     ${IsFileNameProper}

Remove Content Folder And Temp Files
    Append To List	                       ${content_ids_NotWorking}	    ${content_id}
    Run Keyword And Ignore Error           Remove Directory                 ${content_id_folder}
    Remove Unnecessary files in the directory

Downloaded File name is a Match
    [Arguments]                            ${timeout}                       ${cv_row}                                   ${cdl_row}
    ${previous_file_size}=                 Set Variable                     -1
    FOR    ${i}    IN RANGE    ${timeout}
           ${current_file_size}=           Get File Size                    ${download_directory}${/}${downloaded_filename}
           Run Keyword If    '${current_file_size}' == '${previous_file_size}'                                          Exit For Loop
           ${previous_file_size}=          Set Variable                     ${current_file_size}
    END
    ${is_size_stable}=                     Evaluate                         ${current_file_size} == ${previous_file_size}
    Run Keyword If    '${is_size_stable}' == 'False'                        Append To List	                            ${content_ids_NotWorking}	                 ${content_id}
    ${is_source_file_exists}=              Run Keyword And Return Status                                                File Should Exist                            ${download_directory}${/}${downloaded_filename}
    Run Keyword If    '${is_source_file_exists}' == 'False'                 Append To List	                            ${content_ids_NotWorking}	                 ${content_id}
    Run Keyword If    '${is_source_file_exists}' == 'True' and '${is_size_stable}' == 'True'                            Move File                                    ${download_directory}${/}${downloaded_filename}    ${content_id_folder}${/}${file_name}
    ${target_file_exists}=                 Run Keyword And Return Status                                                File Should Exist                            ${content_id_folder}${/}${file_name}
    Log To Console                         SUCCESS: ${file_name} downloaded and moved to ${content_id}
    Run Keyword If    '${target_file_exists}' == 'True'                     Append To List	                            ${content_ids_Working}	                     ${content_id}
    Open Excel Document                    filename=${CV_File_Name}         doc_id=CV_DOC
    Write Excel Cell                       row_num=${cv_row}                col_num=1                                   value=${file_title}
    Write Excel Cell                       row_num=${cv_row}                col_num=2                                   value=${content_id_folder}${/}${file_name}
    Write Excel Cell                       row_num=${cv_row}                col_num=3                                   value=${content_id_folder}${/}${file_name}
    #Write Excel Cell                      row_num=${cv_row}                col_num=4                                   value=${Description}
    #Write Excel Cell                      row_num=${cv_row}                col_num=5                                   value=FirstPublishLocationId
    Save Excel Document                    filename=${CV_File_Name}
    Close Current Excel Document
    Open Excel Document                    filename=${CDL_File_Name}        doc_id=CDL_DOC
    Write Excel Cell                       row_num=${cdl_row}               col_num=1                                   value=${content_doc_id}
    Write Excel Cell                       row_num=${cdl_row}               col_num=2                                   value=${LinkedEntityID}
    Write Excel Cell                       row_num=${cdl_row}               col_num=3                                   value=${ShareType}
    Write Excel Cell                       row_num=${cdl_row}               col_num=4                                   value=${Visibility}
    Save Excel Document                    filename=${CDL_File_Name}
    Close Current Excel Document
    ${actual_file_size}=                   Run Keyword If    '${target_file_exists}' == 'True'                          Get File Size                                ${content_id_folder}${/}${file_name}
    Run Keyword If    '${actual_file_size}' != '${expected_file_size}'      Append To List	                            ${content_ids_NotWorking}	                 ${content_id}
    ${source_still_exists}=                Run Keyword And Return Status    File Should Exist                           ${download_directory}${/}${downloaded_filename}
    Run Keyword If    '${source_still_exists}' == 'True'                    Run Keyword And Ignore Error                Remove File                                  ${download_directory}${/}${downloaded_filename}
    Remove Unnecessary files in the directory

Remove Unnecessary files in the directory
    ${download_dir_path}                   Normalize Path                   ${download_directory}
    Directory Should Exist                 ${download_dir_path}
    ${ListFiles}=                          Evaluate                         [f for f in os.listdir(r'${download_dir_path}') if os.path.isfile(os.path.join(r'${download_dir_path}', f))]    modules=os
    ${Files Count}                         Evaluate                         len($ListFiles)    modules=os
    Log                                    Found ${Files Count} files to delete.
    FOR    ${file}    IN    @{ListFiles}
           ${full_path}                    Evaluate                         os.path.join(r'${download_dir_path}', $file)    modules=os
           ${KeywordStatus}=               Run Keyword And Ignore Error     Evaluate                                    os.remove($full_path)    modules=os
           Set Suite Variable              ${IsFileDeleted}                 ${KeywordStatus}[0]
           Run Keyword If    '${IsFileDeleted}' == 'PASS'                   Log                                         DELETED : ${file}
           Run Keyword If    '${IsFileDeleted}' == 'FAIL'                   Remove File                                 ${full_path}
    END

Log FAILED ContentDocumentID details in Excelfile
    [Arguments]                            ${unique_IDslist_NotWorking}     ${output_directory}
    ${test_name}=                          Replace String                   ${TEST NAME}    ${SPACE}    _
    ${Excel_File}=                         Set Variable                     ${output_directory}${/}${test_name}_FAILED_IDs_List.xlsx
    ${no_of_records}                       Get Length                       ${unique_IDslist_NotWorking}
    Run Keyword If    '${no_of_records}' != '0'                             Write the ContentDocumentIDs                ${unique_IDslist_NotWorking}                 ${Excel_File}

Write the ContentDocumentIDs
    [Arguments]                            ${unique_IDslist_NotWorking}     ${Excel_File}
    ${uuid}=                               Evaluate                         __import__('uuid').uuid4().hex
    Create Excel Document                  ${uuid}
    Write Excel Cell                       row_num=1                        col_num=1                                   value=ContentDocumentId
    ${row}=                                Set Variable    2
    FOR    ${id}    IN     @{unique_IDslist_NotWorking}
           Write Excel Cell                row_num=${row}                   col_num=1                                   value=${id}
           ${row}=                         Evaluate                         ${row} + 1
    END
    Save Excel Document                    filename=${Excel_File}
