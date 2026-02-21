# Set Java 8 environment for FlutterPOS development
$javaHome = "D:\GitHub\java-1.8.0-openjdk-1.8.0.392-1.b08.redhat.windows.x86_64"

# Set JAVA_HOME environment variable
$env:JAVA_HOME = $javaHome

# Add Java bin to PATH
$env:PATH = "$javaHome\bin;$env:PATH"

Write-Host "Java 8 environment configured for FlutterPOS development"
Write-Host "JAVA_HOME: $env:JAVA_HOME"
java -version