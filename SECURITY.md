# Security policy

## Reporting a vulnerability

Report vulnerabilities in this role privately, through [GitHub's private vulnerability reporting](https://github.com/libre-devops/ansible-role-satellite-content-upload/security/advisories/new). Do not open a public issue.

## Things to know

- Keep the Satellite password or personal access token in Ansible Vault or in the `FOREMAN_PASSWORD` environment variable, never in a playbook. The role marks `satellite_content_upload_password` as `no_log`.
- Use a service account that can upload to the repositories and publish the content views it releases, and nothing else.
- The role uploads whatever files you give it. Check what you upload: [`libre_devops.rpm_repo_download`](https://github.com/libre-devops/ansible-role-rpm-repo-download) verifies the vendor's repository signature and each package's checksum before you get this far.
- Keep `validate_certs` on, and point `ca_path` at your CA instead of turning it off.
