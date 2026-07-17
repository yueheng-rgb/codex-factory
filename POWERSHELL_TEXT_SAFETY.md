# PowerShell Text Integrity Safety Rules

> Established after B04 Phase D2 encoding corruption incident.

## Incident Summary

During B04 Phase D2, 11 source files (both in test project and source starter) had their Chinese UTF-8 content corrupted. Root cause: PowerShell `Get-Content -Raw` ? `WriteAllText` pipeline silently re-encoded UTF-8 text through the system's default ANSI code page, producing irreversible mojibake.

## Forbidden Patterns

### NEVER use these on project source files (.ts, .tsx, .js, .json, .md, .css, .html, .yml, .yaml, .env):

```powershell
# DANGEROUS ? encoding depends on PowerShell version and system locale
Get-Content file | Set-Content file
Get-Content file | Out-File file
$content = Get-Content file -Raw; $content -replace "x","y" | Set-Content file
```

```powershell
# DANGEROUS ? Set-Content -Encoding UTF8 adds BOM on Windows PowerShell 5.1
Set-Content -Encoding UTF8 file
Out-File -Encoding UTF8 file
```

```powershell
# DANGEROUS ? redirect operators use default encoding
"text" > file.txt
"text" >> file.txt
```

### NEVER rewrite files that don't need modification:

```powershell
# WRONG ? rewrites all files even when unchanged
Get-ChildItem *.ts | ForEach-Object { $c = Get-Content $_; Set-Content $_ $c }
```

## Required Safe Pattern

All project text file writes MUST use:

```powershell
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllBytes($path, $Utf8NoBom.GetBytes($content))
```

For reading with automatic BOM handling:

```powershell
$rawBytes = [System.IO.File]::ReadAllBytes($path)
$content = if ($rawBytes.Length -ge 3 -and $rawBytes[0] -eq 0xEF -and $rawBytes[1] -eq 0xBB -and $rawBytes[2] -eq 0xBF) {
    $Utf8NoBom.GetString($rawBytes, 3, $rawBytes.Length - 3)
} else {
    $Utf8NoBom.GetString($rawBytes)
}
```

For BOM-only stripping (no content re-encoding):

```powershell
$rawBytes = [System.IO.File]::ReadAllBytes($path)
if ($rawBytes.Length -ge 3 -and $rawBytes[0] -eq 0xEF -and $rawBytes[1] -eq 0xBB -and $rawBytes[2] -eq 0xBF) {
    [System.IO.File]::WriteAllBytes($path, $rawBytes[3..($rawBytes.Length-1)])
}
```

## Modification Principles

1. **Copy-preserve-first**: `Copy-Item` preserves bytes exactly. Only rewrite files that need `PROJECT_NAME` replacement.
2. **Minimal rewrite**: Do not rewrite all files "just to normalize encoding."
3. **Byte-identical guarantee**: Unmodified copied files must have identical SHA256 to source.
4. **Expected-diff-only**: Modified files must differ only in the target placeholder(s).
5. **No charset damage**: Chinese, Japanese, fullwidth punctuation, emoji ? all must survive unchanged.
6. **Fail on `?`**: Any Unicode replacement character (U+FFFD) in output = hard failure.

## Platform-Specific Warnings

| Platform | `Set-Content -Encoding UTF8` | `Out-File -Encoding UTF8` |
|---|---|---|
| Windows PowerShell 5.1 | Adds BOM | Adds BOM |
| PowerShell 7+ | No BOM (default) | No BOM (default) |

**Do not rely on `-Encoding UTF8` behavior.** Use the `[System.IO.File]::WriteAllBytes` pattern exclusively.

## Regression Tests

After any change to copy scripts or text-processing logic:

```powershell
C:\Codex_App_Factory\scripts\test-copy-encoding.ps1
C:\Codex_App_Factory\scripts\test-copy-content-integrity.ps1
```

Both must pass with zero failures before closing a benchmark or shipping a starter change.
