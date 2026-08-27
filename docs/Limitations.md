# Limitations

This page defines the supported boundary of the current repository. Roadmap items are not current capabilities.

## Supported behavior

- Input is an `.xlsx` workbook. The configured worksheet's first column contains 15- or 18-character `ContentDocumentId` values beginning with `069`.
- The workflow downloads the file served for a `ContentDocument` and queries its `LatestPublishedVersionId`. It does not enumerate historical `ContentVersion` records.
- Valid IDs are canonicalized and deduplicated within one batch. One physical binary is saved for each successful unique document in that batch.
- When link output is enabled, every visible `ContentDocumentLink` returned for a successful document can produce a separate migration row.
- Google Chrome is the implemented and tested browser path. Normal execution is headless.
- Files and reports are written to local or locally mounted filesystem paths.
- The repository's CI exercises Python 3.10 and 3.11 on Windows and Ubuntu. Other Python 3.10+ environments are outside that matrix and still require compatible Chrome, filesystem access, and local policy.

## Not supported

- Discovering or selecting files in the Salesforce org; users must supply the IDs.
- Using `ContentVersionId` values, CSV files, or unmodified Salesforce report exports as direct input.
- Downloading complete historical version chains.
- Uploading files or links to a destination Salesforce org.
- Creating the source-to-destination `ContentDocumentId` map required for link import.
- Direct output to Amazon S3, Azure Blob Storage, Google Cloud Storage, or another remote object store.
- Resuming a partial binary from its last byte. Every attempt restarts the file.
- Refreshing an expired Salesforce REST or browser session during a run.
- Automatic deletion or retention management for old run directories.
- Global ID deduplication or coordinated API reservation across parallel workers.
- Guaranteed support for browsers other than Chrome.

## Salesforce API, sessions, and permissions

Each non-empty batch uses the REST limits endpoint and metadata queries. Query pagination can add requests, so the exact API use cannot be known from the number of input IDs alone. The tool does not change the org's API allocation, and parallel workers do not reserve capacity for one another. Salesforce can also report usage with delay.

Binary delivery through Shepherd does not remove the need for REST metadata calls. All requests remain subject to Salesforce availability, org settings, session policy, and the authenticated user's access.

The tool can retrieve only the documents, fields, and links visible to that user. A missing result can mean that the record does not exist or that permission and sharing rules hide it. This repository cannot grant or infer Salesforce access.

If a REST or browser session expires, the relevant work stops. Re-authenticate when necessary, regenerate `org_info.json`, and rerun affected IDs.

## Failure and recovery boundaries

A binary is successful only after completion, stability, `ContentSize` comparison, final movement, destination verification, and any requested workbook commit. A partial, missing, mismatched, or rolled-back file is a failure even if a browser request returned successfully.

Automatic retry is bounded and applies only to structured failures marked as retryable. It cannot correct invalid IDs, missing required metadata, permissions, API capacity, or an expired session. Some retryable-looking conditions can still persist through every attempt and require manual investigation.

Runs can finish with both successful and failed IDs. Successful files remain in their isolated run directory; unresolved IDs are written to a failed-ID workbook when reporting succeeds. If failure reporting itself cannot write a workbook, recovery requires the original input, manifest, and Robot log. The tool does not provide a one-command resume or cross-run reconciliation database.

Workbook transactions attempt to keep migration rows and final binaries consistent. A rare rollback failure can leave a `*_rollback_recovery_*.xlsx` file that requires manual comparison; the tool cannot decide which copy is authoritative.

## Operational and security limits

Runtime depends on Salesforce response time, network throughput, Chrome behavior, file-size distribution, retries, disk speed, and machine resources. Large jobs need space for completed binaries plus temporary downloads, workbooks, manifests, and Robot reports.

Outputs can contain sensitive Salesforce metadata, record IDs, filenames, link relationships, and local paths. `org_info.json` also contains an access token. The project does not encrypt outputs or enforce an organization's access, retention, or sharing policy.

[Back to README](../README.md)
