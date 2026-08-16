# Limitations

- The downloader is designed and validated primarily with Google Chrome.
- A valid Salesforce CLI-authenticated session and generated `org_info.json` are required.
- Authentication is not refreshed during execution; an expired session requires regenerating `org_info.json` and rerunning failed IDs.
- Files are downloaded to local storage.
- Direct uploads to Amazon S3, Azure Blob Storage, and Google Cloud Storage are not part of this repository.
- Partial binary downloads do not resume from the exact byte offset.
- Performance depends on network conditions, Salesforce response times, local hardware resources, browser behavior, disk performance, and file-size distribution.
- Salesforce permissions and `ContentDocumentLink` visibility determine which files and relationships are accessible.
- Some failures require manual review using Robot Framework logs and the generated failure workbooks.
- Large executions require enough local disk space for binaries, workbooks, temporary files, and reports.
- UUID-based run directories under `downloads/`, `artifacts/`, and `results/` are retained for audit and recovery; the downloader does not automatically prune historical runs.
- API-capacity checks are independent REST requests per batch and do not reserve requests globally across simultaneous Pabot workers.
- Metadata request estimates are minimum estimates. Salesforce pagination can add requests that are covered only by the configured safety buffer.
- Daily API usage reported by Salesforce may not reflect every request immediately.
- ID deduplication is performed within each input batch. The same document can still be processed twice when it appears in separate workbooks running on different workers.
- Destination-org inserts and source-to-destination ContentDocument ID mapping are outside this downloader.

---

[← Previous](FAQ.md) | [Next →](Roadmap.md)

[Back to README](../README.md)
