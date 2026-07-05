# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 1.0.1

### Fixed
- Changes from rolled back transactions are no longer included in the aggregated saved changes on a subsequent save.
- Changes rolled back to a savepoint (i.e. a nested transaction with `requires_new: true`) are no longer included in the aggregated saved changes when the outer transaction commits.
- Internal state tracking saved changes is now cleared after every transaction instead of being retained on the instance after transactions with a single save.

## 1.0.0

### Added
- Initial release
