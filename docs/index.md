---
title: R Tools PPA
description: A Personal Package Archive (PPA) for R tools and utilities, providing .deb and .rpm packages for various distributions.
author: Alberson Miranda
date: 2025-06-03
---

# R Tools PPA

This is a Personal Package Archive (PPA) for distributing latest versions of Rstudio, Quarto and Positron for Linux users.

- .deb packages for Ubuntu and Debian-based distributions.
  - Rstudio (amd64 and arm64)
  - Quarto (amd64 and arm64)
  - Positron (amd64 and arm64)
- .rpm packages for Fedora and Red Hat-based distributions.
  - Rstudio (x86_64 and aarch64)
  - Positron (x86_64 and aarch64)
  - Quarto (x86_64)

## Fedora/Red Hat Installation

To enable this repository and install the latest RStudio, Quarto, or Positron:

1. Download the repository file:
    ```sh
    sudo curl -L -o /etc/yum.repos.d/r_tools_ppa.repo \
      https://sourceforge.net/projects/r-tools-ppa/files/rpm_x86_64/repo.txt/download
    ```

    Or for aarch64 architecture:
    ```sh
    sudo curl -o /etc/yum.repos.d/r_tools_ppa.repo \
      https://sourceforge.net/projects/r-tools-ppa/files/rpm_aarch64/repo.txt/download
    ```

2. Update & install (e.g., RStudio):
    ```sh
    sudo dnf update
    sudo dnf install rstudio
    ```

## Debian/Ubuntu Installation

1. Add the repository:
   ```sh
   echo "deb [trusted=yes] https://downloads.sourceforge.net/project/r-tools-ppa/deb_amd64 stable main" | sudo tee /etc/apt/sources.list.d/r_tools_ppa.list
   sudo apt update
   ```

   Or for arm64:
   ```sh
   echo "deb [trusted=yes] https://downloads.sourceforge.net/project/r-tools-ppa/deb_arm64 stable main" | sudo tee /etc/apt/sources.list.d/r_tools_ppa.list
   sudo apt update
   ```

2. Install a package (e.g., RStudio):
   ```sh
   sudo apt install rstudio
   ```
