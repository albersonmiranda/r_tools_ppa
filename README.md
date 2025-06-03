
<!-- README.md is generated from README.Rmd. Please edit that file -->

# R Tools Linux Repository

<!-- badges: start -->

[![upload-rpm](https://github.com/albersonmiranda/r_tools_ppa/actions/workflows/upload_rpm.yaml/badge.svg)](https://github.com/albersonmiranda/r_tools_ppa/actions/workflows/upload_rpm.yaml)
[![upload-deb](https://github.com/albersonmiranda/r_tools_ppa/actions/workflows/upload_deb.yaml/badge.svg)](https://github.com/albersonmiranda/r_tools_ppa/actions/workflows/upload_deb.yaml)
<!-- badges: end -->

This is a Personal Package Archive (PPA) for distributing latest
versions of Rstudio, Quarto and Positron for Linux users.

## Support

- .deb packages for Ubuntu and Debian-based distributions.
  - Rstudio (amd64 and arm64)
  - Quarto (amd64 and arm64)
  - Positron (amd64 and arm64)
- .rpm packages for Fedora and Red Hat-based distributions.
  - Rstudio (x86_64 and aarch64)
  - Positron (x86_64 and aarch64)
  - Quarto (x86_64)

## Debian/Ubuntu Installation

To enable this repository and install the latest RStudio, Quarto, or
Positron:

1.  Add the repository (amd64):

    ``` bash
    echo "deb [trusted=yes] https://downloads.sourceforge.net/project/r-tools-ppa/deb_amd64 stable main" | sudo tee /etc/apt/sources.list.d/r_tools_ppa.list
    sudo apt update
    ```

    Or for arm64:

    ``` bash
    echo "deb [trusted=yes] https://downloads.sourceforge.net/project/r-tools-ppa/deb_arm64 stable main" | sudo tee /etc/apt/sources.list.d/r_tools_ppa.list
    sudo apt update
    ```

2.  Install a package (e.g., RStudio):

    ``` bash
    sudo apt install rstudio
    ```

## Fedora/Red Hat Installation

To enable this repository and install the latest RStudio, Quarto, or
Positron:

1.  Download the repository file:

    ``` bash
    sudo curl -L -o /etc/yum.repos.d/r_tools_ppa.repo \
      https://sourceforge.net/projects/r-tools-ppa/files/rpm_x86_64/repo.txt/download
    ```

    Or for aarch64 architecture:

    ``` bash
    sudo curl -o /etc/yum.repos.d/r_tools_ppa.repo \
      https://sourceforge.net/projects/r-tools-ppa/files/rpm_aarch64/repo.txt/download
    ```

2.  Update & install (e.g., RStudio):

    ``` bash
    sudo dnf update
    sudo dnf install rstudio
    ```
