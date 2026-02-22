# Final fix for unified_pos_screen.dart - Three specific issues to fix
param(
    [string]$InputFile = "E:\extropos\lib\screens\unified_pos_screen.dart.backup",
    [string]$OutputFile = "E:\extropos\lib\screens\unified_pos_screen.dart"
)

# Read file with default encoding
$lines = @()
Get-Content $InputFile -Encoding Default | ForEach-Object { $lines += $_ }

Write-Host "Processing $($lines.Count) lines..."

# Track state for multi-line fixes
$inSearchContainer = $false
$searchContainerLine = -1

for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    
    # FIX 1: ConstrainedBox for search container (lines ~289-291)
    # Pattern: "child: Container(" followed by "maxWidth: 400,"
    if ($line -match '^\s+child: Container\(\s*$' -and !$inSearchContainer) {
        # Check next line for maxWidth
        if ($i+1 -lt $lines.Count -and $lines[$i+1] -match '^\s+maxWidth: 400,\s*$') {
            $indent = $line -replace '^(\s+).*', '$1'
            $lines[$i] = "${indent}child: ConstrainedBox("
            $lines[$i+1] = "${indent}  constraints: const BoxConstraints(maxWidth: 400),"
            # Insert new line for Container
            $lines = $lines[0..$i] + @("${indent}  child: Container(") + $lines[($i+1)..($lines.Count-1)]
            $i += 2  # Skip ahead
            Write-Host "Fixed maxWidth Container at line $i"
            continue
        }
    }
    
    # FIX 2: opacity in TextStyle (line ~364)
    if ($line -match 'opacity: 0\.3') {
        $lines[$i] = $line -replace 'const TextStyle\(', 'TextStyle(' -replace 'opacity: 0\.3', 'color: Colors.white.withOpacity(0.3)'
        Write-Host "Fixed opacity at line $i"
    }
    
    # FIX 3: FontWeight.black (line ~435)
    if ($line -match 'FontWeight\.black') {
        $lines[$i] = $line.Replace('FontWeight.black', 'FontWeight.w900')
        Write-Host "Fixed FontWeight.black at line $i"
    }
}

# Write with UTF-8 no BOM
$utf8 = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllLines($OutputFile, $lines, $utf8)

Write-Host "`nFile saved to: $OutputFile"
Write-Host "Total lines: $($lines.Count)"
