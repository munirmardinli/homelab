# Security Policy

## 🔐 Supported Security Model

This repository contains setup scripts for macOS (bash/zsh), Windows (PowerShell), and Synology, as well as Docker and Docker-Compose configurations.  
There is **no runtime service**, no package manager, and no dependencies beyond system tools.  
Security focuses on **script integrity, safe execution, and protection of sensitive environment files**.

Supported components:

- `bash/` (macOS + Synology setup scripts)
- `windows/` (PowerShell setup scripts)
- `compose/` (Docker-Compose stacks)
- `.env` / secrets used for local deployments

Only the **latest release** is supported for security updates.

---

## ⚠️ Reporting a Vulnerability

If you believe you found a security issue:

1. **Do NOT create a public issue.**
2. Email the maintainer directly:  
   **security@munir.dev** *(or jede gewünschte Adresse — bitte ersetzen falls anders)*  
3. Provide as much detail as possible:
   - Problem description  
   - Steps to reproduce  
   - Affected OS (macOS / Windows / Synology)  
   - Which script:  
     - `bash/darwin/*`  
     - `bash/synology/*`  
     - `windows/*`  
     - `compose/*`  
   - Any logs (redacted)  

You will receive confirmation within **48 hours**, and a fix will be prepared as soon as possible.

---

## 🛡️ Security Expectations

### 1. **Script Integrity**
Always verify:
- You downloaded scripts from the **official releases page**
- You did not modify scripts unless you understand the implications
- You validated checksum/signature if provided (optional future feature)

### 2. **Environment File Safety**
The repository may use:
- `.env`  
- Secret configuration for Docker-Compose  
- Synology SSH config files  
- Shell/Profile configurations

Never commit:
- Passwords  
- API keys  
- TLS certificates  
- Private SSH keys  

### 3. **Docker Security Guidelines**
For the `compose/` directory:
- Always review images before running `docker-compose up`
- Update containers with `docker compose pull`
- Ensure no container exposes unintended public ports
- Use secure volumes for persistent data

### 4. **PowerShell Execution Policy**
Windows users may need:

### 5. **Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned**

Never set `Unrestricted`.

### 5. **Synology Security Notes**
- Do not run scripts as `admin` unless required  
- Use SSH keys instead of passwords  
- Ensure Docker on Synology uses trusted registries  

---

## 🔄 Security Update Process

When a vulnerability is confirmed:

- A **security patch release** will be created
- Release notes will clearly indicate:
  - Issue description
  - Severity
  - Fixed files
  - Recommended user actions
