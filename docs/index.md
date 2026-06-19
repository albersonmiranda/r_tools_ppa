---
title: R Tools PPA
description: A Personal Package Archive (PPA) for R tools and utilities, providing .deb and .rpm packages for various distributions.
author: Alberson Miranda
date: 2025-06-03
---

# R Tools PPA

<div style="padding: 15px; border-left: 5px solid #007bff; background-color: #f0f7ff;">
    <strong>Important:</strong> All packages in this repository are now GPG signed. If you were a user before 2026-06-19, you have to reinstall the repository or update the keys (See section Updating the signing key below).
</div>

This is a Personal Package Archive (PPA) for distributing latest versions of Rstudio, Quarto and Positron for Linux users.

- .deb packages for Ubuntu and Debian-based distributions.
  - Rstudio (amd64)
  - Quarto (amd64 and arm64)
  - Positron (amd64 and arm64)
- .rpm packages for Fedora and Red Hat-based distributions.
  - Rstudio (x86_64)
  - Positron (x86_64 and aarch64)
  - Quarto (x86_64)

## Package signatures

All packages in this repository are signed with the same GPG key:

```
https://downloads.sourceforge.net/project/r-tools-ppa/r_tools_ppa.gpg.key
```

- **Debian/Ubuntu:** APT metadata is signed; install the key before adding the repository.
- **Fedora/Red Hat:** RPM packages are signed; the repository file enables signature verification (`gpgcheck=1`) and points to this key. `dnf` imports it automatically when you enable the repo.

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

    The repo file enables GPG signature verification and references the signing key above. `dnf` imports the key on first use.

2. Update & install (e.g., RStudio):
    ```sh
    sudo dnf update
    sudo dnf install rstudio
    ```

## Debian/Ubuntu Installation

For both amd64 and arm64 architectures:

1. Download and install the signing key:
   ```sh
   sudo curl -fsSL https://downloads.sourceforge.net/project/r-tools-ppa/r_tools_ppa.gpg.key \
     | sudo gpg --dearmor -o /etc/apt/keyrings/r_tools_ppa.gpg
   ```

2. Add the repository:
   ```sh
   echo "deb [arch=amd64,arm64 signed-by=/etc/apt/keyrings/r_tools_ppa.gpg] https://downloads.sourceforge.net/project/r-tools-ppa/deb stable main" | sudo tee /etc/apt/sources.list.d/r_tools_ppa.list
   sudo apt update
   ```

3. Install a package (e.g., Positron):
   ```sh
   sudo apt install positron
   ```

## Updating the signing key

If you enabled this repository before the signing key changed, re-import the key:

**Debian/Ubuntu:**
```sh
sudo curl -fsSL https://downloads.sourceforge.net/project/r-tools-ppa/r_tools_ppa.gpg.key \
  | sudo gpg --dearmor -o /etc/apt/keyrings/r_tools_ppa.gpg
sudo apt update
```

**Fedora/Red Hat:**
```sh
sudo rpm --import https://downloads.sourceforge.net/project/r-tools-ppa/r_tools_ppa.gpg.key
sudo dnf update
```
