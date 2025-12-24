# Salesforce Files Downloader Tool

A powerful **Robot Framework** keyword library designed to efficiently download files from Salesforce using **ContentDocumentId**.

## Overview

This tool simplifies and automates the process of retrieving files (such as documents, attachments, or ContentVersion records) stored in Salesforce. It was built to address real-world inefficiencies in test automation workflows, enabling fast, reliable, and scalable file downloads during QA and regression testing cycles.

**Key Impact**:  
By automating file retrieval, this tool eliminated manual downloads, reduced testing bottlenecks, and contributed to significant operational cost savings (approximately **$1 million** in labor and time efficiencies across multiple release cycles).

## Features

- Download single or multiple files using Salesforce **ContentDocumentId**
- Supports bulk downloads via lists of IDs
- Secure authentication using Salesforce OAuth or username/password (configurable)
- Error handling and detailed logging for debugging
- Easy integration into existing Robot Framework test suites
- Lightweight and dependency-minimal (built with Python and simple-salesforce)

## Why This Tool?

Manual file downloads from Salesforce slowed down test execution and increased human error risk. This custom solution:
- Reduced download time from minutes to seconds per file
- Enabled fully automated end-to-end testing workflows
- Became a standard internal tool adopted across QA teams

## Installation

```bash
pip install robotframework requests simple-salesforce


License
Proprietary – Internal Use Only
This tool is intended for internal company use and is not licensed for redistribution.



Requirements
Python 3.8+
Robot Framework 5.0+
simple-salesforce library
