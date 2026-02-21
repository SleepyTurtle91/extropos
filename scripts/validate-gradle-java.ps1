<#
Validate the Java home used by Gradle in this project.
1) Reads android/gradle.properties for org.gradle.java.home.
2) If set, prints Java version from that JDK path.
3) Prints system default java -version.
4) Runs ./gradlew --version to show which JVM Gradle will use.
#>

$projDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$gradleProps = Join-Path $projDir "..\android\gradle.properties"

Write-Host "Reading: $gradleProps" -ForegroundColor Cyan

if (-not (Test-Path $gradleProps)) {
    Write-Host "gradle.properties not found at $gradleProps" -ForegroundColor Red
    exit 1
}

$lines = Get-Content $gradleProps
$javaHomeLine = $lines | Where-Object { $_ -match '^[^#]*org\.gradle\.java\.home' }

if ($javaHomeLine) {
    $value = ($javaHomeLine -split '=')[1].Trim()
    Write-Host "org.gradle.java.home (in file): $value" -ForegroundColor Green
    $javaBin = Join-Path $value "bin\java.exe"
    if (Test-Path $javaBin) {
        Write-Host "Java found at: $javaBin" -ForegroundColor Green
        & $javaBin -version
    } else {
        Write-Host "Java binary not found at $javaBin" -ForegroundColor Yellow
    }
} else {
    Write-Host "org.gradle.java.home not set in gradle.properties" -ForegroundColor Yellow
}

Write-Host "\nSystem default java -version:" -ForegroundColor Cyan
try { java -version } catch { Write-Host "java not found on PATH" -ForegroundColor Yellow }

Write-Host "\nGradle wrapper version and chosen JVM:" -ForegroundColor Cyan
Push-Location (Join-Path $projDir "..\android")
try { .\gradlew --no-daemon --version } catch { Write-Host "gradlew failed" -ForegroundColor Red }
Pop-Location

Write-Host "\nRecommendation: Use Java 17 or 21 for Gradle 8.x builds. If you need help installing, let me know." -ForegroundColor Cyan

exit 0
