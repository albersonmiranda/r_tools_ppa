---
title: R Tools PPA
---

# R Tools PPA

Welcome to the R Tools Personal Package Archive (PPA)!  
This PPA provides up-to-date R tools and utilities for Linux users.

- .deb packages for Ubuntu and Debian-based distributions.
  - Rstudio
  - Quarto
  - Positron
- .rpm packages for Fedora and Red Hat-based distributions.
  - Rstudio
  - Positron

## Fedora/Red Hat Installation

To enable this repository and install the latest RStudio, Quarto, or Positron:

1. Download the repository file:
    ```{bash, eval = FALSE}
    sudo curl -L -o /etc/yum.repos.d/r_tools_ppa.repo \
      https://sourceforge.net/projects/r-tools-ppa/files/rpm_x86_64/repo.txt/download
    ```

    Or for aarch64 architecture:
    ```{bash, eval = FALSE}
    sudo curl -o /etc/yum.repos.d/r_tools_ppa.repo \
      https://sourceforge.net/projects/r-tools-ppa/files/rpm_aarch64/repo.txt/download
    ```

2. Update & install (e.g., RStudio):
    ```{bash, eval = FALSE}
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
