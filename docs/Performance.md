# Performance

## Recorded benchmark method

The repository records one benchmark dataset:

- 10,000 Salesforce files
- about 6.4 GB total
- 18 file types
- one execution machine
- runs using 1, 2, 4, and 8 workers

No raw benchmark log or script is included. The record does not identify the machine specifications, network connection, Salesforce org conditions, batch distribution, run date, number of repetitions, file-size distribution, or retry and failure counts. The results therefore describe an observed run but are not independently reproducible from this repository alone.

## Measured results

| Workers | Runtime | Reported speedup | Reported efficiency |
|---------|---------|------------------|---------------------|
| 1 | 240 minutes | 1.00× | 100.00% |
| 2 | 121 minutes | 1.98× | 99.17% |
| 4 | 61 minutes | 3.93× | 98.36% |
| 8 | 31 minutes | 7.74× | 96.75% |

These are the figures recorded by the project; they are not a throughput guarantee.

## Interpretation

The recorded workload scaled close to linearly through eight workers on that machine. Another run can differ substantially because every worker adds a Chrome process and because Salesforce response time, network throughput, disk performance, file sizes, permissions, API capacity, session expiry, and retries all affect elapsed time.

Parallel startup and result merging can make a small job slower. A few large files can also leave one worker active after the others finish, even when workbook row counts are equal.

Choose a worker count from representative tests in the actual environment. Start with a small number, observe CPU, memory, disk, network, Salesforce response time, and failure rate, then increase only while the run remains stable. The exact parallel command and isolation requirements are in [Usage](Usage.md#run-parallel-downloads); retry and timeout settings are in [Configuration](Configuration.md).

[Back to README](../README.md)
