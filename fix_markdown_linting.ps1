#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Fixes common markdown linting errors across all .md files in the workspace
    
.DESCRIPTION
    Automatically fixes:
    - MD022: Headings must be surrounded by blank lines
    - MD032: Lists must be surrounded by blank lines
    - Inconsistent spacing in markdown files
    
.PARAMETER Path
    Root path to search for markdown files (default: current directory)
    
.PARAMETER DryRun
    If true, shows what would be changed without making changes
#>

param(
    [string]$Path = ".",
    [switch]$DryRun = $false
)

# Colors for output
$ErrorColor = "Red"
$SuccessColor = "Green"
$WarningColor = "Yellow"
$InfoColor = "Cyan"

Write-Host "🔍 Markdown Linting Fixer - Started at $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor $InfoColor
Write-Host "📁 Scanning: $Path" -ForegroundColor $InfoColor
if ($DryRun) { Write-Host "🏃 DRY RUN MODE - No changes will be made" -ForegroundColor $WarningColor }

# Get all markdown files
$mdFiles = Get-ChildItem -Path $Path -Filter "*.md" -Recurse -ErrorAction SilentlyContinue
$totalFiles = $mdFiles.Count
$fixedFiles = 0
$errorFiles = @()

Write-Host "`n📊 Found $totalFiles markdown files to process`n" -ForegroundColor $InfoColor

# Process each file
foreach ($file in $mdFiles) {
    $filePath = $file.FullName
    $relPath = $file.FullName.Replace($Path, "").TrimStart("\").TrimStart("/")
    
    try {
        # Read file
        $content = Get-Content -Path $filePath -Raw -Encoding UTF8
        $originalContent = $content
        
        # Skip empty files
        if ([string]::IsNullOrWhiteSpace($content)) {
            continue
        }
        
        # Fix 1: MD022 - Ensure blank lines around headings
        # Pattern: heading not preceded by blank line
        $content = [regex]::Replace($content, "([^\n])\n(#{1,6} )", "`$1`n`n`$2")
        
        # Pattern: heading not followed by blank line (except if followed by another heading or EOF)
        $content = [regex]::Replace($content, "(#{1,6} [^\n]+)\n([^\n#])", "`$1`n`n`$2")
        
        # Fix 2: MD032 - Ensure blank lines around lists
        # Pattern: content before list not followed by blank line
        $content = [regex]::Replace($content, "([^\n\-\*])\n(\s*[\-\*\+] )", "`$1`n`n`$2")
        
        # Pattern: list not followed by blank line (except if followed by another list item or EOF)
        $content = [regex]::Replace($content, "(\s*[\-\*\+] [^\n]+)\n([^\s\-\*\+\n])", "`$1`n`n`$2")
        
        # Fix 3: Remove multiple consecutive blank lines (max 2)
        $content = [regex]::Replace($content, "\n\n\n+", "`n`n")
        
        # Fix 4: Ensure file ends with newline
        if ($content -and !$content.EndsWith("`n")) {
            $content += "`n"
        }
        
        # Check if changes were made
        if ($content -ne $originalContent) {
            if ($DryRun) {
                Write-Host "  [WOULD FIX] $relPath" -ForegroundColor $WarningColor
            } else {
                # Write fixed content
                Set-Content -Path $filePath -Value $content -Encoding UTF8 -NoNewline
                Write-Host "  ✅ Fixed: $relPath" -ForegroundColor $SuccessColor
                $fixedFiles++
            }
        }
    }
    catch {
        Write-Host "  ❌ Error processing $relPath : $_" -ForegroundColor $ErrorColor
        $errorFiles += $relPath
    }
}

# Summary
Write-Host "`n" -ForegroundColor $InfoColor
Write-Host "════════════════════════════════════════" -ForegroundColor $InfoColor
Write-Host "✨ MARKDOWN LINTING FIX SUMMARY" -ForegroundColor $InfoColor
Write-Host "════════════════════════════════════════" -ForegroundColor $InfoColor
Write-Host "📊 Total Files Processed: $totalFiles"
Write-Host "✅ Files Fixed: $fixedFiles" -ForegroundColor $SuccessColor
if ($errorFiles.Count -gt 0) {
    Write-Host "❌ Errors: $($errorFiles.Count)" -ForegroundColor $ErrorColor
    Write-Host "`nFiles with errors:"
    $errorFiles | ForEach-Object { Write-Host "  - $_" -ForegroundColor $ErrorColor }
}
Write-Host "════════════════════════════════════════" -ForegroundColor $InfoColor

if ($DryRun) {
    Write-Host "`n🏃 DRY RUN COMPLETED - To apply changes, run:" -ForegroundColor $WarningColor
    Write-Host "   .\fix_markdown_linting.ps1 -Path '$Path'" -ForegroundColor $WarningColor
} else {
    Write-Host "`n✨ Linting fixes completed successfully!" -ForegroundColor $SuccessColor
}
