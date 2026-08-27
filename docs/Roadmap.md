# Roadmap

The items below are ideas for future work. They have no committed release date or final design and must not be treated as current capability.

## Reliability and recovery ideas

- Resumable batch state across separate runs
- Checksum generation and reconciliation
- Coordinated API-capacity reservations across parallel workers
- Salesforce session refresh for long-running work
- More focused tests for browser retry and exhausted-retry paths

## Storage and migration ideas

- Configurable storage layout and retention workflows
- Improved migration reconciliation
- Additional validation and reporting options

## Engineering research

- Other browser compatibility
- Performance profiling and worker-scaling studies
- Coverage reporting that remains practical for local development

Until an item is implemented, tested, and moved into the relevant user guide, rely on the boundaries in [Limitations](Limitations.md).

[Back to README](../README.md)
