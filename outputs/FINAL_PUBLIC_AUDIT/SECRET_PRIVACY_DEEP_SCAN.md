# Secret & Privacy Deep Scan

## Scan Date
2026-07-17

## Scope
READING.md, docs/, outputs/, runtime/, schemas/, reviews/, artifacts/, governance/, .github/, root files

## Patterns Scanned
| Pattern | Description | Hits |
|---|---|---|
| `ghp_[a-zA-Z0-9]{36}` | GitHub Personal Access Token | 0 |
| `gho_[a-zA-Z0-9]{36}` | GitHub OAuth Token | 0 |
| `ghu_[a-zA-Z0-9]{36}` | GitHub User Token | 0 |
| `ghs_[a-zA-Z0-9]{36}` | GitHub Server Token | 0 |
| `ghr_[a-zA-Z0-9]{36}` | GitHub Refresh Token | 0 |
| `sk-(?:or-)?[a-zA-Z0-9]{20,}` | OpenAI API Key | 0 |
| `AKIA[0-9A-Z]{16}` | AWS Access Key | 0 |
| `AIza[0-9A-Za-z\-_]{35}` | GCP API Key | 0 |
| `BEGIN (?:RSA|EC|OPENSSH|DSA) PRIVATE KEY` | Private Key | 0 |
| `eyJ...` (JWT pattern) | JSON Web Token | 0 |

## Filename Scan
| Pattern | Hits |
|---|---|
| `.env` | 0 |
| `auth.json` | 0 |
| `credentials.json` | 0 |
| `*.pem` / `*.pfx` / `*.jks` | 0 |
| `id_rsa` / `id_ed25519` (non-suffixed) | 0 |

## Personal Path Scan
| Pattern | Hits |
|---|---|
| `C:\Users\` (non-Public/Default) | 0 |

## Known False Positives (previously identified)
| File | Pattern | Reason |
|---|---|---|
| `runtime/artifact-sync.ps1` | ghp_ pattern | Regex used to DETECT secrets |
| `runtime/remote-artifact-verifier.ps1` | ghp_ pattern | Regex used to DETECT secrets |
| `PUBLIC_RELEASE_CHECKLIST.md` | ghp_/sk- patterns | Checklist items listing scan patterns |

## Final Verdict
**SECRET_SCAN_PASS** — Zero real secrets, zero real credentials, zero personal paths.
Repository is safe for public release.
