param(
    [string]$Path = ".",
    [switch]$DryRun = $false
)

$startTime = Get-Date -Format "HH:mm:ss"
Write-Host "🔧 Advanced Markdown Linting Fixer - Started at $startTime" -ForegroundColor Cyan
Write-Host "📁 Path: $Path`n" -ForegroundColor Cyan

if ($DryRun) {
    Write-Host "🏃 DRY RUN MODE - No changes will be made`n" -ForegroundColor Yellow
}

$mdFiles = @(Get-ChildItem -Path $Path -Filter "*.md" -Recurse -ErrorAction SilentlyContinue)
$filesFixed = 0
$totalChanges = 0

foreach ($file in $mdFiles) {
    try {
        $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
        if (-not $content) { continue }

        $originalContent = $content
        $changeCount = 0

        # Fix MD040: Add language to bare code fences
        # Match ``` followed by newline (no language specified)
        if ($content -match "```\r?\n") {
            $content = [regex]::Replace($content, "```(\r?\n)([^`])", "```text`$1`$2")
            $changeCount++
        }

        # Fix MD036: Convert emphasis to heading (lines with bold/italic text only)
        # Match lines that start with ** or __ and end with **
        if ($content -match "^\s*\*\*[^*]+\*\*\s*`$") {
            $content = [regex]::Replace($content, "^\s*\*\*([^*]+)\*\*\s*`$", "### `$1", [System.Text.RegularExpressions.RegexOptions]::Multiline)
            $changeCount++
        }

        if ($content -ne $originalContent) {
            $filesFixed++
            $totalChanges += $changeCount
            
            if (-not $DryRun) {
                Set-Content -Path $file.FullName -Value $content -Encoding UTF8 -NoNewline
            }
            
            Write-Host "  ✅ Fixed: $($file.Name)" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "  ❌ Error in $($file.Name): $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n$([char]27)[1;36m" + ("=" * 50) + "$([char]27)[0m"
Write-Host "✨ ADVANCED MARKDOWN FIXES SUMMARY" -ForegroundColor Cyan
Write-Host "$([char]27)[1;36m" + ("=" * 50) + "$([char]27)[0m"
Write-Host "📊 Files Processed: $($mdFiles.Count)"
Write-Host "✅ Files Fixed: $filesFixed"
Write-Host "🔧 Changes Applied: $totalChanges"
Write-Host "$([char]27)[1;36m" + ("=" * 50) + "$([char]27)[0m`n"

Write-Host "📝 Remaining issues require manual attention:"
Write-Host "   - MD013: Line length > 80 characters (disable or reformat manually)"
Write-Host "   - MD060: Table formatting (manual alignment required)"
Write-Host "   - MD036: Emphasis as heading (verify and convert as needed)`n"

if (-not $DryRun) {
    Write-Host "✨ Auto-fixes completed! Run markdownlint to see remaining issues." -ForegroundColor Green
}
