# Limitations

- The downloader is designed and validated primarily with Google Chrome.
- A valid Salesforce CLI-authenticated session and generated `org_info.json` are required.
- Sessions are not refreshed during a run. If one expires, regenerate `org_info.json` and rerun the failed IDs.
- Files are downloaded to local storage.
- The project does not upload directly to Amazon S3, Azure Blob Storage, or Google Cloud Storage.
- Partial binary downloads do not resume from the exact byte offset.
- Performance depends on network conditions, Salesforce response times, local hardware resources, browser behavior, disk performance, and file-size distribution.
- Salesforce permissions and `ContentDocumentLink` visibility determine which files and relationships are accessible.
- Some failures require manual review using Robot Framework logs and the generated failure workbooks.
- Large executions require enough local disk space for binaries, workbooks, temporary files, and reports.
- Run directories are retained for audit and recovery. Old output is not removed automatically.
- Each Pabot worker checks API capacity independently; workers do not share a global request reservation.
- Metadata estimates are minimums. Salesforce pagination may consume part or all of the configured safety buffer.
- Daily API usage reported by Salesforce may not reflect every request immediately.
- ID deduplication is performed within each input batch. The same document can still be processed twice when it appears in separate workbooks running on different workers.
- Importing into the destination org and mapping source IDs to destination IDs are separate steps.

---

[← Previous](FAQ.md) | [Next →](Roadmap.md)

[Back to README](../README.md)
