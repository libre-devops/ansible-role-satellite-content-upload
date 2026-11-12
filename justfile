# Libre DevOps Ansible role libre_devops.satellite_content_upload. Run `just` to list the recipes.
#
# CI runs these same recipes, so a local run shows what CI will do. You need uv
# (https://docs.astral.sh/uv/). Install just with `uv tool install rust-just`
# or `brew install just`.

set shell := ["bash", "-euo", "pipefail", "-c"]

role := "libre_devops.satellite_content_upload"
github_owner := "libre-devops"
github_repo := "ansible-role-satellite-content-upload"


# List the recipes.
default:
    @just --list

# Install the pinned Python tools and the collections the tests use.
deps:
    uv sync --locked
    uv run ansible-galaxy collection install -r requirements.yml -p .ansible/collections

# Lint the YAML, the role (ansible-lint, production profile) and the workflows (zizmor).
lint: deps
    uv run yamllint .
    uv run ansible-lint
    uv run zizmor --offline .github/workflows

# Syntax-check the role through the example playbooks (there is no Satellite to test against
# in CI: use the live recipe for that).
syntax: deps
    uv run ansible-playbook -i localhost, --syntax-check tests/test.yml examples/upload.yml examples/promote.yml

# Run both entry points with nothing to do and a bad value, without a Satellite.
validate: deps
    uv run ansible-playbook -i localhost, -c local tests/validate.yml

# Run the example playbook against real hosts, checks included: just live inventory.ini -e @vars.yml
live inventory *args: deps
    uv run ansible-playbook -i '{{ inventory }}' examples/upload.yml {{ args }}

# Scan the full git history for secrets (needs gitleaks on PATH).
secrets:
    gitleaks git --redact --verbose .

# Tag a release and push the tag. CI then imports it into Galaxy: just release 1.0.0
release version:
    [[ '{{ version }}' =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "version must be semver, for example 1.0.0" >&2; exit 1; }
    git tag -a '{{ version }}' -m 'Release {{ version }}'
    git push origin '{{ version }}'

# scripts/galaxy-import.py says why this does not use `ansible-galaxy role import`.
# Import a release tag into Galaxy, then install it from Galaxy to check (needs GALAXY_API_KEY): just galaxy-import 1.0.0
galaxy-import tag:
    [[ '{{ tag }}' =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "tag must be semver, for example 1.0.0" >&2; exit 1; }
    uv run --no-project python scripts/galaxy-import.py '{{ role }}' '{{ github_owner }}' '{{ github_repo }}' '{{ tag }}'
    dir="$(mktemp -d)" && trap 'rm -rf "$dir"' EXIT && uv run ansible-galaxy role install --roles-path "$dir" '{{ role }},{{ tag }}'
