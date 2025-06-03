# R Tools Linux Repository

This is a Personal Package Archive (PPA) for distributing latest versions of Rstudio, Quarto and Positron for Linux users.

## Support

- .deb packages for Ubuntu and Debian-based distributions.
- .rpm packages for Fedora and Red Hat-based distributions.

## Fedora/Red Hat Installation

To enable this repository and install the latest RStudio, Quarto, or Positron:

1. Download the repository file:
    ```bash
    sudo curl -o /etc/yum.repos.d/r_tools_ppa.repo \
      https://albersonmiranda.github.io/r_tools_ppa/rpm/x86_64/.repo
    ```

2. Update & install (e.g., RStudio):
    ```bash
    sudo dnf update
    sudo dnf install rstudio
    ```
---
