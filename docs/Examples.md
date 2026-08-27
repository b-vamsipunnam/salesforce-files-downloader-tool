# Examples

These scenarios assume installation and authentication are complete. Use [Usage](Usage.md) for the full commands and output review.

## Check access with a small sample

Before a large extraction, put a few representative IDs in `input/Inputfile_1.xlsx`. Include files owned by different teams or linked to different record types, if those are in scope.

Run `Download_Batch_1` only. Review every success in the manifest and confirm that each saved binary opens normally. Resolve permissions, link visibility, browser policy, and disk issues before adding more IDs.

This test is more useful than increasing timeouts immediately: it checks that the chosen Salesforce user can read both the file metadata and the actual files.

## Create a download-only archive

If the job needs local files but not destination-org import workbooks, disable both optional workbook flags for the run:

```bash
robot --test Download_Batch_1 --variable GENERATE_CONTENT_VERSION_FILE:No --variable GENERATE_CONTENT_DOCUMENT_LINK_FILE:No --outputdir results src/robot/orchestrators/download.robot
```

The run still produces validated binaries, a manifest, Robot reports, and a failed-ID workbook when failures remain. Link metadata is not queried when `ContentDocumentLink` output is disabled.

## Split a migration across four workers

Suppose a migration has four non-overlapping groups of file IDs. Put one group in each supplied input workbook and balance the groups by expected data size when that information is available.

Use the test-level Pabot command in [Parallel downloads](Usage.md#run-parallel-downloads). Each worker gets its own Chrome process and UUID-based directories. The four workers still share the Salesforce session file and independently check API capacity.

Do not put the same `ContentDocumentId` in two workbooks. Deduplication is per batch, so overlapping workbooks can download the same physical file twice and create duplicate migration output.

## Recover a failed subset

After a mixed-result run:

1. Read `FailureCode` and `FailureMessage` in the batch's failed-ID workbook.
2. Correct the underlying problem. For an expired session, complete the re-authentication steps in [Authentication](Authentication.md#session-lifetime-and-safety).
3. Copy only the `ContentDocumentId` column into the `Input` worksheet of a clean input template.
4. Run that batch again.

Do not use the generated failed-ID workbook unchanged unless you also configure its actual worksheet name. Its default sheet is not named `Input`.

## Prepare files for a destination migration

Keep both migration flags set to `Yes`. A successful document produces one row in the `ContentVersion` workbook and one or more rows in the `ContentDocumentLink` workbook.

Importing is a separate process:

1. Use the `ContentVersion` workbook and downloaded paths in the approved destination-org import process.
2. Capture the new destination `ContentDocumentId` for every inserted file.
3. Replace each source ID in the link workbook with its corresponding destination ID.
4. Import the remapped links.

The downloader does not perform these imports or build the source-to-destination ID map. Preserve the manifest and migration workbooks together for reconciliation.

[Back to README](../README.md)
