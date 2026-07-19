# Limitations

- The downloader is designed and validated primarily with Google Chrome.
- A valid Salesforce CLI-authenticated session and generated `org_info.json` are required.
- Session expiration may require regeneration of org authentication details and a rerun of failed IDs.
- Files are downloaded to local storage.
- Direct uploads to Amazon S3, Azure Blob Storage, and Google Cloud Storage are not part of this repository.
- Partial binary downloads do not resume from the exact byte offset.
- Performance depends on network conditions, Salesforce response times, local hardware resources, browser behavior, disk performance, and file-size distribution.
- Salesforce permissions and `ContentDocumentLink` visibility determine which files and relationships are accessible.
- Some failures require manual review using Robot Framework logs and the generated failure workbooks.
- Large executions require enough local disk space for binaries, workbooks, temporary files, and reports.
- Authentication is not refreshed automatically during an active execution.
- Destination-org inserts and source-to-destination ContentDocument ID mapping are outside this downloader.

---

[← Previous](FAQ.md) | [Next →](Roadmap.md)

[Back to README](../README.md)
