# Fix unified_pos_screen.dart encoding and syntax issues

$inputFile = "E:\extropos\lib\screens\unified_pos_screen.dart.backup"
$outputFile = "E:\extropos\lib\screens\unified_pos_screen.dart"

# Read with default encoding
$lines = Get-Content $inputFile -Encoding Default

# Process lines
$newLines = @()
$i = 0
while ($i -lt $lines.Count) {
    $line = $lines[$i]
    
    # Fix 1: Change maxWidth in Container to ConstrainedBox
    if ($line -match '^\s+child: Container\(\s*$' -and $i+1 -lt $lines.Count -and $lines[$i+1] -match '^\s+maxWidth: 400,\s*$') {
        $newLines += $line.Replace('child: Container(', 'child: ConstrainedBox(')
        $i++
        $newLines += $lines[$i].Replace('maxWidth: 400,', 'constraints: const BoxConstraints(maxWidth: 400),')
        $i++
        $newLines += "              child: Container("
        continue
    }
    
    # Fix 2: Change opacity in TextStyle to color.withOpacity
    if ($line -match 'opacity: 0\.3') {
        $line = $line.Replace('const TextStyle(', 'TextStyle(')
        $line = $line.Replace('opacity: 0.3', 'color: Colors.white.withOpacity(0.3)')
    }
    
    # Fix 3: Change FontWeight.black to FontWeight.w900
    if ($line -match 'FontWeight\.black') {
        $line = $line.Replace('FontWeight.black', 'FontWeight.w900')
    }
    
    $newLines += $line
    $i++
}

# Write with UTF-8 no BOM
$utf8 = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllLines($outputFile, $newLines, $utf8)

Write-Host "File fixed and saved to $outputFile"
