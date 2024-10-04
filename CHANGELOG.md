# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.0] - 2024-10-04

### Added

- Can include less verbose `TowerSentry` as reporter instead of `TowerSentry.Reporter`.

### Changed

- No longer necessary to call `Tower.attach()` in your application `start`. It is done
automatically.

- Updates `tower` dependency from `{:tower, "~> 0.5.0"}` to `{:tower, "~> 0.6.0"}`.

## [0.2.1] - 2024-09-13

### Added

- Includes user id in Sentry Event report if available

### Dependencies

- Support elixir 1.15+
- Support sentry 10.3+

[0.3.0]: https://github.com/mimiquate/tower_sentry/compare/v0.2.1...v0.3.0/
[0.2.1]: https://github.com/mimiquate/tower_sentry/compare/v0.2.0...v0.2.1/
