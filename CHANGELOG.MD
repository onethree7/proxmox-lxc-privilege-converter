# Changelog

All notable changes to the "proxmox-lxc-privilege-converter" project will be documented in this file.

## [1.0.6] - 2025-07-19
### Added
- **PBS compatibility**: Script now supports backup to and restore from Proxmox Backup Server (PBS) storage.
### Improved
- Modularized and cleaned up all script functions.
- Unified all affirmative input checks via the `yes_choice` helper.
- Modernized prompts and menus with Bash `select` and custom `PS3` prompt strings.
- Improved error handling, input validation, and cleanup logic across all functions.
- All container, storage, and ID inputs are now validated and consistently fall back to safe defaults on error.
- General refactoring for reduced code redundancy, improved readability, and maintainability.
- Help (`-h/--help`) now prints the banner and exits immediately.
- find_next_free_id() removed and inlined.

## [1.0.5] - 2024-11-27
### Added
- Allowing users to select the target container ID. Built-in check to identify all VM/ID IDs already in use.

## [1.0.4] - 2024-03-10
### Fixed
- Unified regex for affirmative input checks, addressing inconsistencies.

### Improved
- Refined feedback in `summarize_actions` to align with actual operations performed.
- Added minimal help function (`-h`, `--help`).

## [1.0.3] - 2024-01-29
### Changed
- Completely simplified `find_next_free_id()` logic with `pvesh get /cluster/nextid`. One command to replace the function.

## [1.0.2] - 2024-01-29
### Changed
- Enhanced `find_next_free_id()` to support Proxmox clusters. Now fetches IDs across all hosts to avoid cluster ID conflicts. (Contributed by haemka.)
- Added CHANGELOG to the repository.

## [1.0.1] - 2023-12-20
### Added
- Improved some functions and minor bugfix.
- Added summary function.

## [1.0.0] - 2023-12-XX
### Added
- Initial release of the lxc_privilege_converter.sh script.
- README and LICENSE files.
