param(
    [string]$Path = ".",
    [switch]$DryRun = $false
)

function Fix-MarkdownLinting {
    param(
        [string]$FilePath,
        [switch]$DryRun
    )

    try {
        $content = Get-Content -Path $FilePath -Raw -Encoding UTF8

        if (-not $content) {
            return @{ Success = $false; Changes = 0 }
        }

        $originalContent = $content
        $changeCount = 0

        # Pattern 1: Fix heading spacing (MD022) - Add blank line BEFORE headings
        if ($content -match "([^\n])\n(#{1,6} )") {
            $content = [regex]::Replace($content, "([^\n])\n(#{1,6} )", "`$1`n`n`$2")
            $changeCount++
        }

        # Pattern 2: Fix heading spacing (MD022) - Add blank line AFTER headings
        if ($content -match "(#{1,6} [^\n]+)\n([^\n#])") {
            $content = [regex]::Replace($content, "(#{1,6} [^\n]+)\n([^\n#])", "`$1`n`n`$2")
            $changeCount++
        }

        # Pattern 3: Fix list spacing (MD032) - Add blank line BEFORE lists
        if ($content -match "([^\n\-\*])\n(\s*[\-\*\+] )") {
            $content = [regex]::Replace($content, "([^\n\-\*])\n(\s*[\-\*\+] )", "`$1`n`n`$2")
            $changeCount++
        }

        # Pattern 4: Fix list spacing (MD032) - Add blank line AFTER lists
        if ($content -match "(\s*[\-\*\+] [^\n]+)\n([^\s\-\*\+\n])") {
            $content = [regex]::Replace($content, "(\s*[\-\*\+] [^\n]+)\n([^\s\-\*\+\n])", "`$1`n`n`$2")
            $changeCount++
        }

        # Pattern 5: Fix MD005 - inconsistent indentation - ensure list items aligned
        if ($content -match "^\s{1,3}[\-\*\+] ") {
            # Normalize list markers to single space indent for top level
            $content = [regex]::Replace($content, "^\s{1,3}([\-\*\+] )", "- ", [System.Text.RegularExpressions.RegexOptions]::Multiline)
            $changeCount++
        }

        # Pattern 6: Fix excessive blank lines (more than 2 consecutive)
        if ($content -match "\n\n\n+") {
            $content = [regex]::Replace($content, "\n\n\n+", "`n`n")
            $changeCount++
        }

        # Pattern 7: Fix MD001 - Multiple top-level headings (ensure only one # at top)
        $lines = $content -split "`n"
        $firstHeadingIndex = -1
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match "^#+ ") {
                if ($firstHeadingIndex -eq -1) {
                    $firstHeadingIndex = $i
                    # Ensure first heading is level 1 only
                    if ($lines[$i] -match "^#{2,} ") {
                        $lines[$i] = $lines[$i] -replace "^#{2,} ", "# "
                        $changeCount++
                    }
                }
                break
            }
        }
        $content = $lines -join "`n"

        # Pattern 8: Fix MD040 - Fenced code blocks need language specified or proper syntax
        if ($content -match "```\s*`n") {
            # Ensure blank lines around code blocks
            $content = [regex]::Replace($content, "([^\n])\n(```)", "`$1`n`n`$2")
            $content = [regex]::Replace($content, "(```)\n([^\n])", "`$1`n`n`$2")
            $changeCount++
        }

        # Pattern 9: Ensure file ends with newline
        if ($content -and -not $content.EndsWith("`n")) {
            $content += "`n"
            $changeCount++
        }

        # Only write if content changed
        if ($content -ne $originalContent) {
            if (-not $DryRun) {
                Set-Content -Path $FilePath -Value $content -Encoding UTF8 -NoNewline
            }
            return @{ Success = $true; Changes = $changeCount }
        }

        return @{ Success = $false; Changes = 0 }
    }
    catch {
        return @{ Success = $false; Error = $_.Exception.Message; Changes = 0 }
    }
}

# Main execution
$startTime = Get-Date -Format "HH:mm:ss"
Write-Host "🔍 Markdown Linting Fixer (Enhanced) - Started at $startTime" -ForegroundColor Cyan
Write-Host "📁 Scanning: $Path" -ForegroundColor Cyan

if ($DryRun) {
    Write-Host "🏃 DRY RUN MODE - No changes will be made`n" -ForegroundColor Yellow
}

# Find all markdown files
$mdFiles = @(Get-ChildItem -Path $Path -Filter "*.md" -Recurse -ErrorAction SilentlyContinue)
Write-Host "📊 Found $($mdFiles.Count) markdown files to process`n"

$filesFixed = 0
$totalChanges = 0
$errors = @()

foreach ($file in $mdFiles) {
    $result = Fix-MarkdownLinting -FilePath $file.FullName -DryRun:$DryRun

    if ($result.Success) {
        $filesFixed++
        $totalChanges += $result.Changes
        
        if ($DryRun) {
            Write-Host "  [WOULD FIX] $($file.FullName)" -ForegroundColor Green
        }
        else {
            Write-Host "  ✅ Fixed: $($file.FullName)" -ForegroundColor Green
        }
    }
    elseif ($result.Error) {
        $errors += $file.FullName
        Write-Host "  ❌ Error: $($file.FullName) - $($result.Error)" -ForegroundColor Red
    }
}

# Summary
Write-Host "`n$([char]27)[1;33m" + ("=" * 40) + "$([char]27)[0m"
Write-Host "✨ MARKDOWN LINTING FIX SUMMARY" -ForegroundColor Yellow
Write-Host "$([char]27)[1;33m" + ("=" * 40) + "$([char]27)[0m"
Write-Host "📊 Total Files Processed: $($mdFiles.Count)"
Write-Host "✅ Files Fixed: $filesFixed"
Write-Host "🔧 Total Changes Applied: $totalChanges"

if ($errors.Count -gt 0) {
    Write-Host "❌ Errors: $($errors.Count)" -ForegroundColor Red
    foreach ($err in $errors) {
        Write-Host "   - $err" -ForegroundColor Red
    }
}

Write-Host "$([char]27)[1;33m" + ("=" * 40) + "$([char]27)[0m`n"

if ($DryRun) {
    Write-Host "🏃 DRY RUN COMPLETED - To apply changes, run:" -ForegroundColor Cyan
    Write-Host "   .\fix_markdown_linting_enhanced.ps1 -Path '$Path'" -ForegroundColor White
}
else {
    Write-Host "✨ Linting fixes completed successfully!" -ForegroundColor Green
}
