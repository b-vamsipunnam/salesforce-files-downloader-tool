# Introduction

Salesforce Files stores documents, images, and other uploaded files. Salesforce separates the file itself from its versions and from the records where the file appears.

The downloader uses three standard Salesforce objects:

- `ContentDocument` is the logical file. Its ID, called `ContentDocumentId`, starts with `069`.
- `ContentVersion` represents one version of that file. Its `VersionData` field contains the binary content—the actual file bytes.
- `ContentDocumentLink` connects the file to a Salesforce record, user, group, or library and stores sharing details.

Information such as IDs, titles, sizes, and record links is **metadata**. It describes a file but is not the file content itself.

## When this tool is useful

Use the downloader when you already have a list of `ContentDocumentId` values and need local copies for a migration, archive, backup process, or review. It can also create workbooks that help prepare the downloaded files and their record links for a separate destination-org import.

One file can have several `ContentDocumentLink` records. The downloader therefore saves one physical file for each unique `ContentDocument` in a batch while keeping each visible link as a separate migration record when link output is enabled.

The tool is designed to make incomplete work visible. A file is successful only after the transfer finishes and its final size is validated. Missing files, incomplete files, and unresolved workbook updates remain failures.

## What it does not do

The tool does not find file IDs for you, import files into another Salesforce org, map source IDs to destination IDs, refresh expired sessions during a run, or resume partway through a binary file. See [Limitations](Limitations.md) for the full boundary.

[Back to README](../README.md)
