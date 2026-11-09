# Changelog

Notable changes to this role. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow [Semantic Versioning](https://semver.org/).

## Unreleased

### Added

- First release.
- Upload files to Satellite or Foreman Katello repositories with `theforeman.foreman.content_upload`, skipping files already there.
- Publish content views in order when something was uploaded (or always, or never) and promote each new version to lifecycle environments.
- Check each uploaded file is in its repository.
- A `promote` entry point to promote content view versions between lifecycle environments.
- Connection settings from variables or the `FOREMAN_*` environment variables.
