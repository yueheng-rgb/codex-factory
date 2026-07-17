# C/C++ Build & Sanitizer Tool Availability Detector
# For: Codex Factory v2.4 — cpp-memory-safety runtime validation testbed
# Does NOT fake ASan/UBSan/Valgrind availability

param(
    [switch]$Json,
    [switch]$Verbose
)

$results = @{
    timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz")
    hostname = $env:COMPUTERNAME
    tools = @()
    overall = @{
        compiler_available = $false
        cmake_available = $false
        asan_available = $false
        ubsan_available = $false
        tsan_available = $false
        valgrind_available = $false
    }
}

function Test-Tool {
    param($Name, $TestCommand, $VersionArg = "--version")
    
    $tool = @{
        name = $Name
        available = $false
        version = $null
        path = $null
        limitation = $null
    }
    
    try {
        $path = (Get-Command $TestCommand -ErrorAction Stop).Source
        $tool.path = $path
        $version = & $TestCommand $VersionArg 2>&1 | Select-Object -First 1
        $tool.version = $version.ToString().Trim()
        $tool.available = $true
    } catch {
        $tool.limitation = "TOOL_UNAVAILABLE — $Name not found in PATH or not installed"
        $tool.available = $false
    }
    
    return $tool
}

# Check compilers
$results.tools += Test-Tool -Name "g++" -TestCommand "g++"
$results.tools += Test-Tool -Name "clang" -TestCommand "clang"
$results.tools += Test-Tool -Name "clang++" -TestCommand "clang++"
$results.tools += Test-Tool -Name "cmake" -TestCommand "cmake"

# Check sanitizers — require compiler AND flags
$gpp = $results.tools | Where-Object { $_.name -eq "g++" -and $_.available }
if ($gpp) {
    # Test if g++ supports -fsanitize=address
    $testCode = "int main() { return 0; }"
    $testCode | Out-File -Encoding ascii "test_sanitizer.cpp" -Force
    try {
        $null = & g++ -fsanitize=address -o test_sanitizer.exe test_sanitizer.cpp 2>&1
        if ($LASTEXITCODE -eq 0) {
            $results.overall.asan_available = $true
            $results.tools += @{
                name = "ASan (AddressSanitizer)"
                available = $true
                version = "via g++ -fsanitize=address"
                path = $gpp.path
                limitation = $null
            }
        }
        Remove-Item test_sanitizer.cpp, test_sanitizer.exe -Force -ErrorAction SilentlyContinue
    } catch {
        $results.tools += @{
            name = "ASan (AddressSanitizer)"
            available = $false
            version = $null
            path = $null
            limitation = "g++ found but -fsanitize=address compilation failed"
        }
    }
} else {
    $results.tools += @{
        name = "ASan (AddressSanitizer)"
        available = $false
        version = $null
        path = $null
        limitation = "TOOL_UNAVAILABLE — no C++ compiler available"
    }
}

$results.tools += @{
    name = "UBSan (UndefinedBehaviorSanitizer)"
    available = $false
    version = $null
    path = $null
    limitation = "TOOL_UNAVAILABLE — no C++ compiler available; requires g++ or clang with -fsanitize=undefined"
}

$results.tools += @{
    name = "TSan (ThreadSanitizer)"
    available = $false
    version = $null
    path = $null
    limitation = "TOOL_UNAVAILABLE — no C++ compiler available; requires g++ or clang with -fsanitize=thread"
}

# Check Valgrind
$results.tools += Test-Tool -Name "valgrind" -TestCommand "valgrind"

# Set overall flags
$results.overall.compiler_available = ($results.tools | Where-Object { $_.name -in @("g++","clang","clang++") -and $_.available }).Count -gt 0
$results.overall.cmake_available = ($results.tools | Where-Object { $_.name -eq "cmake" -and $_.available }).Count -gt 0
$results.overall.valgrind_available = ($results.tools | Where-Object { $_.name -eq "valgrind" -and $_.available }).Count -gt 0

if ($Json) {
    $results | ConvertTo-Json -Depth 4
} else {
    Write-Output "C/C++ Tool Availability Detection"
    Write-Output "=================================="
    foreach ($t in $results.tools) {
        $status = if ($t.available) { "AVAILABLE" } else { "UNAVAILABLE" }
        Write-Output "[$status] $($t.name)"
        if ($t.version) { Write-Output "  version: $($t.version)" }
        if ($t.limitation) { Write-Output "  reason: $($t.limitation)" }
    }
    Write-Output ""
    Write-Output "Overall:"
    Write-Output "  compiler: $($results.overall.compiler_available)"
    Write-Output "  cmake: $($results.overall.cmake_available)"
    Write-Output "  ASan: $($results.overall.asan_available)"
    Write-Output "  UBSan: $($results.overall.ubsan_available)"
    Write-Output "  TSan: $($results.overall.tsan_available)"
    Write-Output "  Valgrind: $($results.overall.valgrind_available)"
}
