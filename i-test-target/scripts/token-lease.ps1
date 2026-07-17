# Token Lease 闂?Phase 6A.2 Harness Hardening
# Manages per-task agent tokens with role-scoped operations.
# Tokens are issued, validated, and revoked via an external hash-only store.
# Plaintext tokens are NEVER persisted 闂?only SHA256 hashes are stored.
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("issue","validate","revoke","sign","verify-proof")]
    [string]$Action,

    [Parameter(Mandatory=$true)]
    [string]$RunId,

    # --- issue parameters ---
    [Parameter(Mandatory=$false)]
    [string]$TaskId,
    [Parameter(Mandatory=$false)]
    [string]$AgentId,
    [Parameter(Mandatory=$false)]
    [ValidateSet("orchestrator","spec-agent","builder-agent","test-agent","release-agent")]
    [string]$Role,
    [Parameter(Mandatory=$false)]
    [int]$TtlSeconds = 3600,
    [Parameter(Mandatory=$false)]
    [string[]]$AllowedOperations = @(),

    # --- validate parameters ---
    [Parameter(Mandatory=$false)]
    [string]$Token,
    [Parameter(Mandatory=$false)]
    [string]$Operation,

    # --- sign / verify-proof parameters (Phase 6A.3) ---
    [Parameter(Mandatory=$false)]
    [string]$EventCanonicalJson,
    [Parameter(Mandatory=$false)]
    [string]$AuthorizationProof,
    [Parameter(Mandatory=$false)]
    [string]$ProofNonce,
    [Parameter(Mandatory=$false)]
    [string]$TokenLeaseId,[Parameter(Mandatory=$false)][string]$EventTimestamp
)

$ErrorActionPreference = "Stop"

$HarnessRoot     = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$TokenStoreRoot  = Join-Path $HarnessRoot "..\harness-control\tokens"
$TokenStoreDir   = Join-Path $TokenStoreRoot $RunId
$IntegrityFile   = Join-Path $TokenStoreDir "_integrity.json"

# ------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------

function Write-JsonFile {
    param([string]$Path, $Object)
    $utf8 = [System.Text.UTF8Encoding]::new($false)
    $json = $Object | ConvertTo-Json -Depth 6 -Compress
    [System.IO.File]::WriteAllText($Path, $json, $utf8)
}

function Read-JsonFile {
    param([string]$Path)
    if (-not (Test-Path $Path)) { throw "File not found: $Path" }
    Get-Content -Raw -Path $Path | ConvertFrom-Json
}

function Get-Sha256 {
    param([string]$InputString)
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($InputString)
    $hash  = [System.Security.Cryptography.SHA256]::Create().ComputeHash($bytes)
    return [System.BitConverter]::ToString($hash).Replace("-","").ToLower()
}

function Get-Sha256-File {
    param([string]$Path)
    if (-not (Test-Path $Path)) { throw "File not found for hashing: $Path" }
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    $hash  = [System.Security.Cryptography.SHA256]::Create().ComputeHash($bytes)
    return [System.BitConverter]::ToString($hash).Replace("-","").ToLower()
}

function New-RandomToken {
    $random = [byte[]]::new(48)
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($random)
    return [System.Convert]::ToBase64String($random)
}

function Update-Integrity {
    $tokenFiles = Get-ChildItem -Path $TokenStoreDir -Filter "*.json" -File | Where-Object { $_.Name -ne "_integrity.json" } |
        Where-Object { $_.Name -ne "_integrity.json" } |
        Sort-Object Name

    $hashes = @()
    foreach ($tf in $tokenFiles) {
        $hashes += @{
            file   = $tf.Name
            sha256 = Get-Sha256-File $tf.FullName
        }
    }

    $integrity = @{
        schemaVersion = "6A.2"
        runId         = $RunId
        updatedAt     = (Get-Date).ToString("o")
        fileCount     = $hashes.Count
        files         = $hashes
        rootHash      = if ($hashes.Count -gt 0) {
            Get-Sha256 (($hashes | ForEach-Object { "$($_.file):$($_.sha256)" }) -join "|")
        } else { "" }
    }

    Write-JsonFile -Path $IntegrityFile -Object $integrity
}

# ------------------------------------------------------------------
# Action: issue
# ------------------------------------------------------------------

if ($Action -eq "issue") {
    if (-not $TaskId) { throw "issue requires -TaskId" }
    if (-not $AgentId) { throw "issue requires -AgentId" }
    if (-not $Role)    { throw "issue requires -Role" }

    if (-not (Test-Path $TokenStoreDir)) {
        New-Item -ItemType Directory -Path $TokenStoreDir -Force | Out-Null
    }

    $plaintext = New-RandomToken
    $tokenHash = Get-Sha256 $plaintext
    $now       = (Get-Date).ToUniversalTime()
    $expiresAt = $now.AddSeconds($TtlSeconds).ToString("o")
    $issuedAt  = $now.ToString("o")
    $nonce     = [System.Guid]::NewGuid().ToString("N")
    $leaseId   = [System.Guid]::NewGuid().ToString("N")
    $tokenFile = Join-Path $TokenStoreDir "$leaseId.json"

    # Never persist plaintext 闁?hash only. Each lease is a unique, non-overwritable file.
    $record = @{
        schemaVersion     = "6B-R5"
        leaseId           = $leaseId
        taskId            = $TaskId
        agentId           = $AgentId
        role              = $Role
        issuedAt          = $issuedAt
        expiresAt         = $expiresAt
        tokenHash         = $tokenHash
        allowedOperations = $AllowedOperations
        nonce             = $nonce
        revokedAt         = $null
        status            = "active"
    }

    Write-JsonFile -Path $tokenFile -Object $record
    Update-Integrity

    # Return plaintext only to caller (stdout)
    Write-Output (@{
        status       = "issued"
        leaseId      = $leaseId
        taskId       = $TaskId
        agentId      = $AgentId
        role         = $Role
        token        = $plaintext
        tokenHash    = $tokenHash
        issuedAt     = $issuedAt
        expiresAt    = $expiresAt
        nonce        = $nonce
        tokenStoreDir = $TokenStoreDir
    } | ConvertTo-Json -Depth 4)
    exit 0
}

# ------------------------------------------------------------------
# Action: validate
# ------------------------------------------------------------------

if ($Action -eq "validate") {
    if (-not $Token)     { throw "validate requires -Token" }
    if (-not $TaskId)    { throw "validate requires -TaskId" }

    $tokenHash = Get-Sha256 $Token

    # Find matching token file
    $candidateFiles = Get-ChildItem -Path $TokenStoreDir -Filter "*.json" -File -ErrorAction SilentlyContinue
    if (-not $candidateFiles) {
        Write-Output (@{ status="invalid"; reason="no_token_store"; tokenStoreDir=$TokenStoreDir } | ConvertTo-Json)
        exit 1
    }

    $match = $null
    foreach ($cf in $candidateFiles) {
        $rec = Read-JsonFile $cf.FullName
        if ($rec.tokenHash -eq $tokenHash -and $rec.taskId -eq $TaskId) {
            $match = $rec
            break
        }
    }

    if (-not $match) {
        Write-Output (@{ status="invalid"; reason="token_hash_mismatch"; taskId=$TaskId } | ConvertTo-Json)
        exit 1
    }

    # Check revocation
    if ($match.revokedAt -ne $null) {
        Write-Output (@{ status="invalid"; reason="revoked"; revokedAt=$match.revokedAt; taskId=$TaskId } | ConvertTo-Json)
        exit 1
    }

    # Check expiry
    $expires = [DateTime]::Parse($match.expiresAt, $null, [System.Globalization.DateTimeStyles]::RoundtripKind)
    if ((Get-Date).ToUniversalTime() -gt $expires.ToUniversalTime()) {
        Write-Output (@{ status="invalid"; reason="expired"; expiresAt=$match.expiresAt; taskId=$TaskId } | ConvertTo-Json)
        exit 1
    }

    # Check operation is allowed (only if Operation parameter provided)
    if ($Operation -and $match.allowedOperations.Count -gt 0 -and $match.allowedOperations -notcontains $Operation) {
        Write-Output (@{
            status     = "invalid"
            reason     = "operation_not_allowed"
            operation  = $Operation
            allowed    = $match.allowedOperations
            taskId     = $TaskId
        } | ConvertTo-Json)
        exit 1
    }

    Write-Output (@{
        status       = "valid"
        taskId       = $TaskId
        agentId      = $match.agentId
        role         = $match.role
        issuedAt     = $match.issuedAt
        expiresAt    = $match.expiresAt
        nonce        = $match.nonce
        tokenStoreDir = $TokenStoreDir
    } | ConvertTo-Json -Depth 4)
    exit 0
}

# ------------------------------------------------------------------
# Action: revoke
# ------------------------------------------------------------------

if ($Action -eq "revoke") {
    if (-not $Token)  { throw "revoke requires -Token" }
    if (-not $TaskId) { throw "revoke requires -TaskId" }

    $tokenHash = Get-Sha256 $Token

    $candidateFiles = Get-ChildItem -Path $TokenStoreDir -Filter "*.json" -File -ErrorAction SilentlyContinue
    if (-not $candidateFiles) {
        Write-Output (@{ status="not_found"; reason="no_token_store"; tokenStoreDir=$TokenStoreDir } | ConvertTo-Json)
        exit 1
    }

    $match     = $null
    $matchFile = $null
    foreach ($cf in $candidateFiles) {
        $rec = Read-JsonFile $cf.FullName
        if ($rec.tokenHash -eq $tokenHash -and $rec.taskId -eq $TaskId) {
            $match     = $rec
            $matchFile = $cf.FullName
            break
        }
    }

    if (-not $match) {
        Write-Output (@{ status="not_found"; reason="token_hash_mismatch"; taskId=$TaskId } | ConvertTo-Json)
        exit 1
    }

    if ($match.revokedAt -ne $null) {
        Write-Output (@{ status="already_revoked"; revokedAt=$match.revokedAt; taskId=$TaskId } | ConvertTo-Json)
        exit 1
    }

    $match | Add-Member -NotePropertyName revokedAt -NotePropertyValue (Get-Date).ToUniversalTime().ToString("o") -Force
    Write-JsonFile -Path $matchFile -Object $match
    Update-Integrity

    Write-Output (@{
        status       = "revoked"
        taskId       = $TaskId
        agentId      = $match.agentId
        role         = $match.role
        revokedAt    = $match.revokedAt
        tokenStoreDir = $TokenStoreDir
    } | ConvertTo-Json -Depth 4)
    exit 0
}


# ------------------------------------------------------------------
# Action: sign (Phase 6A.3 - generate authorization proof)
# ------------------------------------------------------------------

if ($Action -eq "sign") {
    if (-not $Token)     { throw "sign requires -Token" }
    if (-not $TaskId)    { throw "sign requires -TaskId" }
    if (-not $Operation) { throw "sign requires -Operation" }
    
    if (-not $EventCanonicalJson) { throw "sign requires -EventCanonicalJson" }
    
    # Validate the token first
    $tokenHash = Get-Sha256 $Token
    
    $candidateFiles = Get-ChildItem -Path $TokenStoreDir -Filter "*.json" -File -ErrorAction SilentlyContinue
    if (-not $candidateFiles) {
        Write-Output (@{ status="invalid"; reason="no_token_store" } | ConvertTo-Json)
        exit 1
    }
    
    $match = $null; $matchFile = $null
    foreach ($cf in $candidateFiles) {
        $rec = Read-JsonFile $cf.FullName
        if ($rec.tokenHash -eq $tokenHash -and $rec.taskId -eq $TaskId) {
            $match = $rec; $matchFile = $cf.FullName; break
        }
    }
    
    if (-not $match) {
        Write-Output (@{ status="invalid"; reason="token_hash_mismatch" } | ConvertTo-Json)
        exit 1
    }
    
    if ($match.revokedAt -ne $null) {
        Write-Output (@{ status="invalid"; reason="revoked" } | ConvertTo-Json)
        exit 1
    }
    
    $expires = [DateTime]::Parse($match.expiresAt, $null, [System.Globalization.DateTimeStyles]::RoundtripKind)
    if ((Get-Date).ToUniversalTime() -gt $expires.ToUniversalTime()) {
        Write-Output (@{ status="invalid"; reason="expired" } | ConvertTo-Json)
        exit 1
    }
    
    if ($match.allowedOperations.Count -gt 0 -and $match.allowedOperations -notcontains $Operation) {
        Write-Output (@{ status="invalid"; reason="operation_not_allowed"; operation=$Operation; allowed=$match.allowedOperations } | ConvertTo-Json)
        exit 1
    }
    
    # Generate proof nonce
    $proofNonce = [System.Guid]::NewGuid().ToString("N")
    
    # Normalize event canonical JSON (sort keys, just like validate-state does)
    try {
        $eventObj = $EventCanonicalJson | ConvertFrom-Json
        $normalized = [ordered]@{}
        foreach ($key in ($eventObj.PSObject.Properties.Name | Sort-Object)) {
            $normalized[$key] = $eventObj.$key
        }
        $normalizedJson = ($normalized | ConvertTo-Json -Compress -Depth 6)
    } catch {
        $normalizedJson = $EventCanonicalJson
    }
    
    # Compute authorization proof: SHA256(tokenHash + nonce + eventCanonicalHash + operation + taskId)
    $eventCanonicalHash = Get-Sha256 $normalizedJson
    $proofInput = "$tokenHash|$proofNonce|$eventCanonicalHash|$Operation|$TaskId"
    $proof = Get-Sha256 $proofInput
    
    # Record the nonce as issued (not yet consumed)
    if (-not $match.issuedNonces) { $match | Add-Member -NotePropertyName issuedNonces -NotePropertyValue @() -Force }
    if (-not $match.consumedNonces) { $match | Add-Member -NotePropertyName consumedNonces -NotePropertyValue @() -Force }
    $match.issuedNonces += @{ nonce=$proofNonce; operation=$Operation; issuedAt=(Get-Date).ToString("o"); consumed=$false }
    Write-JsonFile -Path $matchFile -Object $match
    Update-Integrity
    
    Write-Output (@{
        status = "signed"
        taskId = $TaskId
        agentId = $match.agentId
        role = $match.role
        operation = $Operation
        authorizationProof = $proof
        tokenLeaseId = $tokenHash
        nonce = $proofNonce
        issuedAt = $match.issuedAt
        expiresAt = $match.expiresAt
        tokenStoreDir = $TokenStoreDir
    } | ConvertTo-Json -Depth 4)
    exit 0
}

# ------------------------------------------------------------------
# Action: verify-proof (Phase 6A.3 - verify authorization proof)
# ------------------------------------------------------------------

if ($Action -eq "verify-proof") {
    if (-not $TaskId)          { throw "verify-proof requires -TaskId" }
    if (-not $Operation)       { throw "verify-proof requires -Operation" }
    if (-not $EventCanonicalJson) { throw "verify-proof requires -EventCanonicalJson" }
    if (-not $AuthorizationProof) { throw "verify-proof requires -AuthorizationProof" }
    if (-not $ProofNonce)      { throw "verify-proof requires -ProofNonce" }
    if (-not $TokenLeaseId)    { throw "verify-proof requires -TokenLeaseId" }
    
    # Find the token record by tokenLeaseId
    $candidateFiles = Get-ChildItem -Path $TokenStoreDir -Filter "*.json" -File -ErrorAction SilentlyContinue
    if (-not $candidateFiles) {
        Write-Output (@{ status="invalid"; reason="no_token_store" } | ConvertTo-Json)
        exit 1
    }
    
    $match = $null; $matchFile = $null
    foreach ($cf in $candidateFiles) {
        $rec = Read-JsonFile $cf.FullName
        if ($rec.tokenHash -eq $TokenLeaseId) {
            $match = $rec; $matchFile = $cf.FullName; break
        }
    }
    
    if (-not $match) {
        Write-Output (@{ status="invalid"; reason="lease_not_found"; leaseId=$TokenLeaseId } | ConvertTo-Json)
        exit 1
    }
    
    # Check expiry — use EventTimestamp if provided (durable audit), else current time
    if ($match.expiresAt) {
        $expires = [DateTime]::Parse($match.expiresAt, $null, [System.Globalization.DateTimeStyles]::RoundtripKind)
        if ($EventTimestamp) {
            $eventTime = [DateTime]::Parse($EventTimestamp, $null, [System.Globalization.DateTimeStyles]::RoundtripKind)
            if ($eventTime.ToUniversalTime() -gt $expires.ToUniversalTime()) {
                Write-Output (@{ status="invalid"; reason="event_time_after_expiry"; eventTimestamp=$EventTimestamp; expiresAt=$match.expiresAt } | ConvertTo-Json)
                exit 1
            }
            if ($match.issuedAt) {
                $issuedAt = [DateTime]::Parse($match.issuedAt, $null, [System.Globalization.DateTimeStyles]::RoundtripKind)
                if ($eventTime.ToUniversalTime() -lt $issuedAt.ToUniversalTime()) {
                    Write-Output (@{ status="invalid"; reason="event_time_before_issuance"; eventTimestamp=$EventTimestamp; issuedAt=$match.issuedAt } | ConvertTo-Json)
                    exit 1
                }
            }
        } else {
            if ((Get-Date).ToUniversalTime() -gt $expires.ToUniversalTime()) {
                Write-Output (@{ status="invalid"; reason="expired" } | ConvertTo-Json)
                exit 1
            }
        }
    }
    
    # Check nonce was issued (read-only: verify-proof is idempotent)
    $issuedNonces = @($match.issuedNonces)
    $nonceIssued = $issuedNonces | Where-Object { $_.nonce -eq $ProofNonce }
    if (-not $nonceIssued) {
        Write-Output (@{ status="invalid"; reason="nonce_not_issued"; nonce=$ProofNonce } | ConvertTo-Json)
        exit 1
    }
    
    # NOTE: verify-proof is READ-ONLY. Nonce consumption happens only at event submission
    # (when a new event is signed with a nonce). Re-verification of existing events is allowed.
    
    # Normalize and recompute proof (same normalization as sign)
    try {
        $eventObj = $EventCanonicalJson | ConvertFrom-Json
        $normalized = [ordered]@{}
        foreach ($key in ($eventObj.PSObject.Properties.Name | Sort-Object)) {
            $normalized[$key] = $eventObj.$key
        }
        $normalizedJson = ($normalized | ConvertTo-Json -Compress -Depth 6)
    } catch {
        $normalizedJson = $EventCanonicalJson
    }
    $eventCanonicalHash = Get-Sha256 $normalizedJson
    $proofInput = "$($match.tokenHash)|$ProofNonce|$eventCanonicalHash|$Operation|$TaskId"
    $expectedProof = Get-Sha256 $proofInput
    
    if ($expectedProof -ne $AuthorizationProof) {
        Write-Output (@{ status="invalid"; reason="proof_mismatch"; expected=$expectedProof; provided=$AuthorizationProof } | ConvertTo-Json)
        exit 1
    }
    
    # READ-ONLY: Do NOT modify token store. Do NOT consume nonce. Do NOT update integrity.
    
    Write-Output (@{
        status = "verified"
        taskId = $TaskId
        agentId = $match.agentId
        role = $match.role
        operation = $Operation
        nonce = $ProofNonce
        tokenStoreDir = $TokenStoreDir
        idempotent = $true
    } | ConvertTo-Json -Depth 4)
    exit 0
}
throw "Unknown action: $Action"
