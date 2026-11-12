<div align="center">
  <a href="https://libredevops.org">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://libredevops.org/assets/libre-devops-white.png">
      <img alt="Libre DevOps" src="https://libredevops.org/assets/libre-devops-black.png" width="300">
    </picture>
  </a>
</div>

# Ansible Role: Satellite content upload

Uploads RPMs (and other content) to Red Hat Satellite or Foreman with Katello, publishes the content views that use them, promotes the new versions to lifecycle environments, and checks the files arrived. A separate entry point promotes between environments without uploading, for example from Test to Production once testing has passed.

[![CI](https://github.com/libre-devops/ansible-role-satellite-content-upload/actions/workflows/ci.yml/badge.svg)](https://github.com/libre-devops/ansible-role-satellite-content-upload/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/libre-devops/ansible-role-satellite-content-upload?sort=semver&label=release)](https://github.com/libre-devops/ansible-role-satellite-content-upload/releases/latest)
[![Galaxy](https://img.shields.io/badge/galaxy-libre__devops.satellite__content__upload-EE0000?logo=ansible&logoColor=white)](https://galaxy.ansible.com/ui/standalone/roles/libre_devops/satellite_content_upload/documentation/)
[![Licence](https://img.shields.io/github/license/libre-devops/ansible-role-satellite-content-upload)](./LICENSE)

---

> **Status:** linted, syntax-checked and argument-validated in CI. Not yet run against a real Satellite: test with `just live` before relying on it.

## What it does

| Entry point | What happens |
|---|---|
| `main` (default) | 1. Checks every file in `satellite_content_upload_uploads` exists on the host the role runs on. 2. Uploads each one to its product and repository. A file already in the repository (same name and checksum) is not uploaded again. 3. Publishes each content view in `satellite_content_upload_content_views`, in order, when something was uploaded (or always, or never), and promotes the new version to its lifecycle environments. 4. Looks each file up in its repository to prove it arrived. |
| `promote` | Promotes the content view version in one lifecycle environment to others. Uploads nothing. Idempotent. |

The role uses the [`theforeman.foreman`](https://galaxy.ansible.com/ui/repo/published/theforeman/foreman/) collection, the upstream of Red Hat's `redhat.satellite`: the modules are the same.

It is one stage of a release pipeline: [`ansible-mde-satellite-release`](https://github.com/libre-devops/ansible-mde-satellite-release) uses it to stage Microsoft Defender for Endpoint to a test Satellite and release it to production after testing.

## Contents

- [Requirements](#requirements)
- [Installation](#installation)
- [Quick start](#quick-start)
- [Role variables](#role-variables)
- [Connecting and signing in](#connecting-and-signing-in)
- [Two ways to stage and release](#two-ways-to-stage-and-release)
- [Examples](#examples)
- [Troubleshooting](#troubleshooting)
- [Developing](#developing)
- [Releasing](#releasing)

## Requirements

| What | Detail |
|---|---|
| Control node | `ansible-core` 2.16 or later and the `theforeman.foreman` collection (5.x or 6.x). |
| Host the role runs on | Usually the control node (`hosts: localhost`). It needs the files, the Python packages `requests` and `PyYAML`, and either the `rpm` command or the `rpm` Python bindings, which `content_upload` uses to read RPM headers. On Ubuntu or WSL: `apt install rpm python3-requests python3-yaml`. On RHEL: `dnf install python3-requests python3-pyyaml` (the `rpm` command is already there). |
| Satellite | An existing product and repository for each upload, and content views that include those repositories. The role does not create them. The user needs permission to upload to the repositories and to publish and promote the content views. |

## Installation

```bash
ansible-galaxy role install libre_devops.satellite_content_upload
ansible-galaxy collection install theforeman.foreman
```

Or pin a release from GitHub in a `requirements.yml`:

```yaml
roles:
  - name: libre_devops.satellite_content_upload
    src: https://github.com/libre-devops/ansible-role-satellite-content-upload.git
    scm: git
    version: 1.0.0
collections:
  - name: theforeman.foreman
```

Without Galaxy, or to keep a copy inside your organisation, see [Using the role without Galaxy](./docs/using-without-galaxy.md). It covers git, release archives, requirements files that point at your own servers, AWX and Automation Controller, and execution environments.

## Quick start

```yaml
- name: Upload to Satellite
  hosts: localhost
  gather_facts: false
  roles:
    - role: libre_devops.satellite_content_upload
      vars:
        satellite_content_upload_server_url: https://satellite.example.com
        satellite_content_upload_organization: Example Org
        satellite_content_upload_uploads:
          - product: Microsoft
            repository: Microsoft el9
            files:
              - releases/el9/mdatp-101.25092.0005.x86_64.rpm
        satellite_content_upload_content_views:
          - name: Microsoft el9
            lifecycle_environments: [Test]
```

```bash
export FOREMAN_USERNAME=svc-content FOREMAN_PASSWORD='...'
ansible-playbook upload.yml
```

A second run with the same file changes nothing, so nothing is published twice.

## Role variables

Every variable is validated against [`meta/argument_specs.yml`](./meta/argument_specs.yml) when the role starts, including each entry of the lists. Defaults are in [`defaults/main.yml`](./defaults/main.yml).

### Connection

| Variable | Default | Description |
|---|---|---|
| `satellite_content_upload_server_url` | `""` | Satellite URL. Empty uses `FOREMAN_SERVER_URL`. |
| `satellite_content_upload_username` | `""` | User. Empty uses `FOREMAN_USERNAME`. |
| `satellite_content_upload_password` | `""` | Password or personal access token. Empty uses `FOREMAN_PASSWORD`. |
| `satellite_content_upload_validate_certs` | `true` | Check the Satellite's TLS certificate. |
| `satellite_content_upload_ca_path` | `""` | CA bundle for the Satellite's certificate when it is not in the system store. Empty uses `FOREMAN_CA_PATH`. |
| `satellite_content_upload_organization` | `""` | Organisation. |

### Upload and publish (`main`)

| Variable | Default | Description |
|---|---|---|
| `satellite_content_upload_uploads` | `[]` | Files to upload, as `product`, `repository` and `files` (paths on the host the role runs on). |
| `satellite_content_upload_content_views` | `[]` | Content views to publish, in order (components before composites), each with `name` and the `lifecycle_environments` to promote the new version to. Library is always included. |
| `satellite_content_upload_publish` | `changed` | `changed` publishes only when an upload added something, `always` every run, `never` not at all. |
| `satellite_content_upload_publish_description` | `Published by Ansible` | Description of each new content view version. Put the package version or change number in it. |
| `satellite_content_upload_verify` | `true` | After uploading, look each file up in its repository. |

### Promote (`tasks_from: promote`)

| Variable | Default | Description |
|---|---|---|
| `satellite_content_upload_promotions` | `[]` | Each with `content_view`, `from` (the environment whose version is promoted) and `to` (a list of environments). |

The `promote` entry point also uses the connection variables.

## Connecting and signing in

The `theforeman.foreman` modules take their connection settings from the task or from environment variables. The role passes only the variables you set, so you can keep credentials out of your playbooks:

```bash
export FOREMAN_SERVER_URL=https://satellite.example.com
export FOREMAN_USERNAME=svc-content
export FOREMAN_PASSWORD='...'          # or a personal access token
export FOREMAN_CA_PATH=/etc/pki/tls/certs/ca-bundle.crt
```

Or set `satellite_content_upload_password` from Ansible Vault. Use a service account limited to the products and content views it releases, and a personal access token rather than a password where your Satellite allows it.

## Two ways to stage and release

Both work with this role. Pick the one that matches your Satellites.

**One Satellite, lifecycle environments.** Upload once, publish and promote to Test, test, then promote Test to Production with the `promote` entry point. The package is uploaded once.

```yaml
satellite_content_upload_content_views:
  - name: Microsoft el9
    lifecycle_environments: [Test]
# after testing:
satellite_content_upload_promotions:
  - content_view: Microsoft el9
    from: Test
    to: [Production]
```

**Separate test and production Satellites.** Run `main` against the test Satellite, test, then run `main` again with the same files against the production one. The checksum check proves production gets exactly the file that was tested.

## Examples

### Several RHEL versions at once

```yaml
satellite_content_upload_uploads:
  - product: Microsoft
    repository: Microsoft el8
    files: [releases/el8/mdatp-101.25092.0005.x86_64.rpm]
  - product: Microsoft
    repository: Microsoft el9
    files: [releases/el9/mdatp-101.25092.0005.x86_64.rpm]
satellite_content_upload_content_views:
  - name: Microsoft el8
    lifecycle_environments: [Test]
  - name: Microsoft el9
    lifecycle_environments: [Test]
```

### A composite content view

List the component first, then the composite, so the composite picks up the new component version:

```yaml
satellite_content_upload_content_views:
  - name: Microsoft el9
  - name: RHEL 9 servers
    lifecycle_environments: [Test]
```

### Upload only

```yaml
satellite_content_upload_publish: never
```

### More examples

[`examples/upload.yml`](./examples/upload.yml) and [`examples/promote.yml`](./examples/promote.yml).

## Troubleshooting

| Symptom | What to check |
|---|---|
| `... does not exist on localhost` | The paths in `files` are relative to where you run `ansible-playbook`, or the role runs on a different host from the files. |
| A message saying `rpm` is required | Install the `rpm` command (`apt install rpm`) or the `rpm` Python bindings on the host the role runs on. |
| `requests` or `yaml` import errors | Install `requests` and `PyYAML` for the Python that Ansible uses on that host. |
| 401 Unauthorized | Wrong user, password or token, or `FOREMAN_*` variables set in another shell. |
| SSL certificate errors | Set `satellite_content_upload_ca_path` (or `FOREMAN_CA_PATH`) to the CA that signed the Satellite's certificate. Avoid turning `validate_certs` off. |
| `Found 0 repositories called ...` | The product or repository name differs from the one in Satellite. Names are case sensitive. |
| Published, but hosts do not see the package | The repository is not in the content view, or the hosts are subscribed to a different content view or lifecycle environment. |

## Developing

You need [uv](https://docs.astral.sh/uv/) and [just](https://github.com/casey/just). CI runs the same recipes.

| Recipe | What it does |
|---|---|
| `just deps` | Installs the pinned Python tools (`uv.lock`) and `theforeman.foreman` into `.ansible/`. |
| `just lint` | `yamllint`, `ansible-lint` on the production profile, and `zizmor` on the workflows. |
| `just syntax` | Syntax-checks the role through [`tests/test.yml`](./tests/test.yml) and the examples. |
| `just validate` | Runs both entry points with nothing to do, and a bad value, to check the argument specifications. No Satellite needed. |
| `just live <inventory> [args]` | Runs [`examples/upload.yml`](./examples/upload.yml) against a real Satellite. |
| `just secrets` | Scans the git history with gitleaks. |

There is no Satellite in CI, so uploads, publishing and promotion are tested against a real Satellite with `just live`.

## Releasing

1. Move the Unreleased entries in [`CHANGELOG.md`](./CHANGELOG.md) under the new version.
2. Run `just release 1.2.3`. It tags the commit and pushes the tag.
3. The Release workflow creates the GitHub release, imports the tag into Galaxy, which takes the version from the tag, and installs it back from Galaxy to check. It needs the `GALAXY_API_KEY` secret, which the libre-devops organisation provides. The import goes through Galaxy's API with [`scripts/galaxy-import.py`](./scripts/galaxy-import.py), not `ansible-galaxy role import`, because Galaxy namespaces cannot contain a hyphen: the role namespace is `libre_devops` and the GitHub organisation is `libre-devops`, which that command cannot handle. If the import fails, fix the cause and run the Release workflow by hand with the tag to import it again.

## Sources

| Topic | Source |
|---|---|
| `content_upload`, `content_view_version`, `resource_info` and the connection options | [theforeman/foreman-ansible-modules](https://github.com/theforeman/foreman-ansible-modules) |

## Licence

[MIT](./LICENSE).
