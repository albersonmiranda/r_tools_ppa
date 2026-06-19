# R Tools Linux Repository

<!-- badges: start -->

[![upload-rpm](https://github.com/albersonmiranda/r_tools_ppa/actions/workflows/upload_rpm.yaml/badge.svg)](https://github.com/albersonmiranda/r_tools_ppa/actions/workflows/upload_rpm.yaml)
[![upload-deb](https://github.com/albersonmiranda/r_tools_ppa/actions/workflows/upload_deb.yaml/badge.svg)](https://github.com/albersonmiranda/r_tools_ppa/actions/workflows/upload_deb.yaml)
<!-- badges: end -->

> [!IMPORTANT]
> All packages in this repository are now GPG signed. If you were a user before 2026-06-19, you have to reinstall the repository or [update the keys](#updating-the-signing-key).

This is a Personal Package Archive (PPA) for distributing latest
versions of Rstudio, Quarto and Positron for Linux users.

## Support

-   .deb packages for Ubuntu and Debian-based distributions.
    -   Rstudio (amd64)
    -   Quarto (amd64 and arm64)
    -   Positron (amd64 and arm64)
-   .rpm packages for Fedora and Red Hat-based distributions.
    -   Rstudio (x86\_64)
    -   Positron (x86\_64 and aarch64)
    -   Quarto (x86\_64)

## Package signatures

All packages in this repository are signed with the same GPG key:

    https://downloads.sourceforge.net/project/r-tools-ppa/r_tools_ppa.gpg.key

-   **Debian/Ubuntu:** APT metadata is signed; install the key before
    adding the repository (see below).
-   **Fedora/Red Hat:** RPM packages are signed; the repository file
    enables signature verification (`gpgcheck=1`) and points to this
    key. `dnf` imports it automatically when you enable the repo.

## Debian/Ubuntu Installation

To enable this repository and install the latest RStudio, Quarto, or
Positron:

1.  Download and install the signing key:

        sudo curl -fsSL https://downloads.sourceforge.net/project/r-tools-ppa/r_tools_ppa.gpg.key \
          | sudo gpg --dearmor -o /etc/apt/keyrings/r_tools_ppa.gpg

2.  Add the repository:

        echo "deb [arch=amd64,arm64 signed-by=/etc/apt/keyrings/r_tools_ppa.gpg] https://downloads.sourceforge.net/project/r-tools-ppa/deb stable main" | sudo tee /etc/apt/sources.list.d/r_tools_ppa.list
        sudo apt update

3.  Install a package (e.g., RStudio):

        sudo apt install rstudio

## Fedora/Red Hat Installation

To enable this repository and install the latest RStudio, Quarto, or
Positron:

1.  Download the repository file:

        sudo curl -L -o /etc/yum.repos.d/r_tools_ppa.repo \
          https://sourceforge.net/projects/r-tools-ppa/files/rpm_x86_64/repo.txt/download

    Or for aarch64 architecture:

        sudo curl -o /etc/yum.repos.d/r_tools_ppa.repo \
          https://sourceforge.net/projects/r-tools-ppa/files/rpm_aarch64/repo.txt/download

    The repo file enables GPG signature verification and references
    the signing key above. `dnf` imports the key on first use.

2.  Update & install (e.g., RStudio):

        sudo dnf update
        sudo dnf install rstudio

## Updating the signing key

If you enabled this repository before the signing key changed, re-import
the key:

**Debian/Ubuntu:**

    sudo curl -fsSL https://downloads.sourceforge.net/project/r-tools-ppa/r_tools_ppa.gpg.key \
      | sudo gpg --dearmor -o /etc/apt/keyrings/r_tools_ppa.gpg
    sudo apt update

**Fedora/Red Hat:**

    sudo rpm --import https://downloads.sourceforge.net/project/r-tools-ppa/r_tools_ppa.gpg.key
    sudo dnf update

## Maintainer notes

See [docs/maintainer.md](docs/maintainer.md) for repository automation
and GPG signing setup.
