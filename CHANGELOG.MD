# Changelog

All notable changes to the "proxmox-lxc-privilege-converter" project will be documented in this file.

## [1.0.5] - 2024-11-27
### Added
- Allowing users to select the target container ID. Built in check to identify all VM/ID Ids already in use.

## [1.0.4] - 2024-03-10
### Fixed
- Unified regex for affirmative input checks, addressing inconsistencies.

### Improved
- Refined feedback in `summarize_actions` to align with actual operations performed.
- Added minimal help function (-h --help)

## [1.0.3] - 2024-01-29
### Changed
- Completley simplified `find_next_free_id()` logfic with `pvesh get /cluster/nextid` now. One command to replace the function.

## [1.0.2] - 2024-01-29
### Changed
- Enhanced `find_next_free_id()` function to support Proxmox clusters. Previously, the function only worked for single PVE-hosts, leading to potential ID conflicts in cluster environments. The fix, contributed by haemka, involves using `pvesh` to fetch existing IDs across all hosts, ensuring unique ID allocation in both single-host and cluster setups. 
- added CHANGELOG to the repository

## [1.0.1] - 2023-12-20
### Added
- Improved some functions and minor bugfix.
- Added summary function.

## [1.0.0] - 2023-12-XX
### Added
- Initial release of the lxc_privilege_converter.sh script
- README and LICENSE files
