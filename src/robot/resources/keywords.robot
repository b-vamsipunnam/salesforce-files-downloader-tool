*** Settings ***
Documentation       Public resource entry point for the Salesforce Files Bulk Downloader.

Resource            configuration.robot
Resource            salesforce_cli.robot
Resource            salesforce_api.robot
Resource            excel_operations.robot
Resource            download_operations.robot
Resource            download_workflow.robot
Resource            cleanup.robot
