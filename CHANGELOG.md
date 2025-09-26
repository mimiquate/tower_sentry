# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.5] - 2025-09-26

### Added

- New `mix tower_sentry.install` task.

## [0.3.4] - 2025-07-12

### Added

- Allow use with sentry 11.x (i.e. Updates `sentry` dependency requirement from `{:sentry, "~> 10.3"}` to `{:sentry, "~> 10.3 or ~> 11.0"}`)

## [0.3.3] - 2025-02-26

### Added

- Allow use with tower 0.8.x (i.e. Updates `tower` dependency requirement from `{:tower, "~> 0.7.1"}` to `{:tower, "~> 0.7.1 or ~> 0.8.0"}`)

## [0.3.2] - 2024-12-18

### Added

- Include in the report whether the exception was handled or unhandled

## [0.3.1] - 2024-11-19

### Fixed

- Properly format reported throw values

### Changed

- Updates `tower` dependency from `{:tower, "~> 0.6.0"}` to `{:tower, "~> 0.7.1"}`.

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

[0.3.5]: https://github.com/mimiquate/tower_sentry/compare/v0.3.4...v0.3.5/
[0.3.4]: https://github.com/mimiquate/tower_sentry/compare/v0.3.3...v0.3.4/
[0.3.3]: https://github.com/mimiquate/tower_sentry/compare/v0.3.2...v0.3.3/
[0.3.2]: https://github.com/mimiquate/tower_sentry/compare/v0.3.1...v0.3.2/
[0.3.1]: https://github.com/mimiquate/tower_sentry/compare/v0.3.0...v0.3.1/
[0.3.0]: https://github.com/mimiquate/tower_sentry/compare/v0.2.1...v0.3.0/
[0.2.1]: https://github.com/mimiquate/tower_sentry/compare/v0.2.0...v0.2.1/
