*** Settings ***
Documentation       Defines shared paths, timeouts, batch sizes, temporary-file markers, and other downloader configuration values.


*** Variables ***
# Temporary browser download markers and runtime-generated artifacts used during cleanup.
@{TEMP_FILE_SUFFIXES}           .crdownload    .tmp    .part
@{TEMP_FILES}
...                             CDL_DOC
...                             CV_DOC
...                             PIPE
...                             smoke_doc
...                             org_info.json

# Salesforce CLI-generated organization authentication metadata file.
${ORG_INFO_FILE}                org_info.json

# Standard project directories for input files, isolated downloads, and generated artifacts.
${INPUT_FOLDER}                 ${EXECDIR}${/}input
${BASE_DOWNLOAD_FOLDER}         ${EXECDIR}${/}downloads
${OUTPUT_FOLDER}                ${EXECDIR}${/}artifacts

# Download timing controls for file appearance, completion, and stability validation.
${DOWNLOAD_APPEAR_TIMEOUT}      60s
${DOWNLOAD_COMPLETE_TIMEOUT}    60s
${FILE_STABILITY_MAX_CHECKS}    60
${FILE_STABILITY_INTERVAL}      0.25s

# File move retry controls for temporary Windows file locks.
${FILE_MOVE_TIMEOUT}            15s
${FILE_MOVE_RETRY_INTERVAL}     500ms

# Number of ContentDocument IDs processed per SOQL metadata batch query.
${METADATA_BATCH_SIZE}          200
