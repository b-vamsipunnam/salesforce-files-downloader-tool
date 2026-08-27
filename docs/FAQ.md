# Frequently asked questions

## Does the downloader change the source Salesforce org?

The workflow reads API limits and file metadata and requests file downloads. It does not create, update, or delete Salesforce records. The optional workbooks are local files for a later migration process.

## Which file types can it download?

The workflow does not use a file-extension allow-list. It builds the local name from the Salesforce title and `FileExtension`, or from the title alone when no extension is present. Actual success still depends on Salesforce access, browser delivery, local path rules, disk space, and size validation; the recorded benchmark's 18 file types are not a formal compatibility list.

## Why can a local filename differ from the Salesforce title?

Characters that are invalid in local filenames are replaced, Windows reserved names are protected, and long names can be shortened to keep the complete path within the configured limit. The `ContentVersion` migration workbook keeps the source title, with spreadsheet-formula prefixes escaped for safety.

## Do I need to learn Robot Framework, Selenium, or Pabot?

Not for a normal sequential run. Robot Framework is the task runner behind the documented `robot` command, and Selenium controls Chrome. Pabot is needed only when you choose parallel batch execution. Contributors extending keywords should use [Keyword documentation](Keyword-Documentation.md).

For setup, output, retry, API, migration, and recovery questions, use the canonical [Usage](Usage.md), [Configuration](Configuration.md), [Troubleshooting](Troubleshooting.md), and [Limitations](Limitations.md) pages instead of this FAQ.

[Back to README](../README.md)
