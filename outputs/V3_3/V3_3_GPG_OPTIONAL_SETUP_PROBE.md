# V3.3 — GPG Optional Setup Probe

## Probe Result

| Field | Value |
|-------|-------|
| GPG available | No |
| Fingerprint present | No |
| Status | GPG_UNAVAILABLE_WITH_INSTALL_NOTES |

## Install Instructions

| OS | Command |
|----|---------|
| Windows | Install Gpg4win from https://gpg4win.org/ |
| Linux | `sudo apt install gnupg` |
| macOS | `brew install gnupg` |

## After Install

```bash
gpg --gen-key    # Generate test key only (NOT company identity)
gpg --list-keys  # Verify key exists
```

## Non-Claims

- GPG is OPTIONAL — not required for V3.3
- Do NOT generate company/organization GPG keys
- Test keys only, not production identity
- fingerprint_present=true does NOT mean production-ready identity
- No private key material collected or stored