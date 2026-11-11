# Changelog

Notable changes to this role. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow [Semantic Versioning](https://semver.org/).

## Unreleased

### Added

- `docs/using-without-galaxy.md`, linked from the README's Installation section: installing the role without Galaxy (git, release archives, requirements files that name their own source), getting its collections with no Galaxy access, keeping a copy on your own git server or artifact store, AWX, Automation Controller and execution environments, and the ansible-core and Python versions it needs.

### Changed

- The Release workflow imports the release's own tag into Galaxy, rather than the default branch, and can be run by hand with a tag to import that tag again.

## 1.0.0 - 2026-11-11

### Added

- First release.
- Upload files to Satellite or Foreman Katello repositories with `theforeman.foreman.content_upload`, skipping files already there.
- Publish content views in order when something was uploaded (or always, or never) and promote each new version to lifecycle environments.
- Check each uploaded file is in its repository.
- A `promote` entry point to promote content view versions between lifecycle environments.
- Connection settings from variables or the `FOREMAN_*` environment variables.
