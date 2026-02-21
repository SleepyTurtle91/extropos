<#
set_java_home.ps1 - Helper to set JAVA_HOME to installed Eclipse Temurin JDKs
Usage:
  .\set_java_home.ps1            # Sets JAVA_HOME to latest JDK (prefers 21+ then 8)
  .\set_java_home.ps1 -Version 21
  .\set_java_home.ps1 -Version 8
#>
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('8','21','Latest')]
    [string]
    $Version = 'Latest'
)

$installRoot = 'C:\Program Files\Eclipse Adoptium'
if (-not (Test-Path $installRoot)) { Write-Host "No Eclipse Adoptium install dir found at $installRoot" -ForegroundColor Red; exit 1 }

switch ($Version) {
    '8' {
        $match = '^jdk-8'
    }
    '21' {
        $match = '^jdk-21'
    }
    default {
        # prefer 21+, then 8
        $jdk = Get-ChildItem -Path $installRoot -Directory | Where-Object { $_.Name -match '^jdk-2' } | Sort-Object Name -Descending | Select-Object -First 1
        if ($jdk) { $match = '^jdk-2'; break } else { $match = '^jdk-8' }
    }
}

$jdkDir = Get-ChildItem -Path $installRoot -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match $match } | Sort-Object Name -Descending | Select-Object -First 1
if (-not $jdkDir) { Write-Host "Requested JDK version not found under $installRoot" -ForegroundColor Red; exit 1 }

$jdkPath = $jdkDir.FullName
[Environment]::SetEnvironmentVariable('JAVA_HOME',$jdkPath,'User')

# Ensure $JAVA_HOME\bin is in User PATH
$current = [Environment]::GetEnvironmentVariable('Path','User')
$binPath = "$jdkPath\bin"
if (-not ($current -split ';' | Where-Object { $_ -eq $binPath })) {
    [Environment]::SetEnvironmentVariable('Path', "$current;$binPath", 'User')
    Write-Host "Added $binPath to User PATH" -ForegroundColor Green
} else {
    Write-Host "$binPath already present in User PATH" -ForegroundColor Yellow
}

Write-Host "JAVA_HOME set to: $jdkPath" -ForegroundColor Cyan
Write-Host "Restart any open terminals or VS Code to pick up changes." -ForegroundColor Yellow