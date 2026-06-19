# Maintainer notes

This are my personal notes with steps I have to do manually when changing machines, mail accounts, passwords or local testing.

## Workflows

This repository is updated automatically by GitHub Actions and published to [SourceForge](https://sourceforge.net/projects/r-tools-ppa/).

| Workflow | Schedule (UTC) | Script |
|----------|----------------|--------|
| [upload_deb.yaml](../.github/workflows/upload_deb.yaml) | Daily 04:00 | `scripts/update_deb.sh` |
| [upload_rpm.yaml](../.github/workflows/upload_rpm.yaml) | Daily 03:00 | `scripts/update_rpm.sh` |

Both workflows can also be triggered manually (`workflow_dispatch`).

## GitHub secrets

| Secret | Purpose |
|--------|---------|
| `GPG_PRIVATE_KEY` | ASCII-armored GPG private key for signing |
| `GPG_PASSPHRASE` | Passphrase for the signing key |
| `SF_SFTP_USER` | SourceForge SFTP username |
| `SF_SFTP_PASS` | SourceForge SFTP password |

The same GPG key is used for both `.deb` and `.rpm` repositories.

## Public signing key

The public key must be available at:

```
https://downloads.sourceforge.net/project/r-tools-ppa/r_tools_ppa.gpg.key
```

Export and upload after creating or rotating a key:

```sh
gpg --armor --export albersonmiranda@hotmail.com > r_tools_ppa.gpg.key
```

## GPG key setup

Generate a new key:

```sh
gpg --full-generate-key
```

Currently `albersonmiranda@hotmail.com`, but I'll eventually move to Proton Mail.

Export for GitHub Actions:

```sh
gpg --armor --export-secret-keys albersonmiranda@hotmail.com
```

Add the output to the `GPG_PRIVATE_KEY` secret and the passphrase to `GPG_PASSPHRASE`.

## Signing behavior

**Debian (`.deb`):** `update_deb.sh` signs APT `Release` metadata (`InRelease` and `Release.gpg`).

**RPM:** `update_rpm.sh` re-signs all packages with the repository key using `rpm --resign`. Upstream RStudio and Positron RPMs arrive pre-signed; they are replaced with the PPA signature so clients need only one trusted key.

## Local testing

```sh
export GPG_PASSPHRASE='your-passphrase'
bash scripts/update_deb.sh
bash scripts/update_rpm.sh   # requires Fedora/RHEL tools (rpmbuild, createrepo_c, rpm-sign)
```

Verify Debian signing:

```sh
gpg --verify deb/dists/stable/InRelease
```

Verify RPM signing:

```sh
rpm -Kv rpm/x86_64/*.rpm
```
