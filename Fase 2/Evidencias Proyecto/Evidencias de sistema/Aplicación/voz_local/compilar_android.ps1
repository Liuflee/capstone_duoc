# Compila en una ruta sin acentos: el generador AOT de Windows falla con
# algunas rutas Unicode. No modifica ni cierra la aplicación de escritorio.
$ErrorActionPreference = 'Stop'
$aplicacion = Split-Path -Parent $PSScriptRoot
$repositorio = (& git -C $aplicacion rev-parse --show-toplevel).Trim()
if ($LASTEXITCODE -ne 0) { throw 'Ejecuta este script dentro del repositorio del proyecto.' }
$preparacion = Join-Path $repositorio '.compilacion_android'
$sdkAnterior = $env:ANDROID_HOME
New-Item -ItemType Directory -Force -Path $preparacion | Out-Null
foreach ($carpeta in @('android', 'lib', 'assets')) {
    & robocopy (Join-Path $aplicacion $carpeta) (Join-Path $preparacion $carpeta) /E /XD .gradle .kotlin .cxx build /XF local.properties /NFL /NDL /NJH /NJS | Out-Null
    if ($LASTEXITCODE -ge 8) { throw "No se pudo copiar $carpeta para compilar." }
}
foreach ($archivo in @('pubspec.yaml', 'pubspec.lock')) {
    Copy-Item -LiteralPath (Join-Path $aplicacion $archivo) -Destination $preparacion -Force
}
$sdkLocal = Join-Path $repositorio '.android-sdk'
if (Test-Path -LiteralPath $sdkLocal) { $env:ANDROID_HOME = $sdkLocal }
Push-Location $preparacion
try {
    flutter pub get
    if ($LASTEXITCODE -ne 0) { throw 'No se pudieron preparar las dependencias Flutter.' }
    $argumentos = @('build', 'apk', '--release', '--split-per-abi', '--target-platform', 'android-arm64',
        '--no-pub', "--dart-define-from-file=$(Join-Path $aplicacion 'supabase.config.json')")
    & flutter @argumentos
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo compilar la APK.' }
    $carpetaSalida = Join-Path $aplicacion 'build\app\outputs\flutter-apk'
    New-Item -ItemType Directory -Force -Path $carpetaSalida | Out-Null
    Copy-Item -LiteralPath 'build\app\outputs\flutter-apk\app-arm64-v8a-release.apk' -Destination $carpetaSalida -Force
    Write-Host "APK de prueba para Android de 64 bits: $carpetaSalida\app-arm64-v8a-release.apk"
} finally {
    Pop-Location
    $env:ANDROID_HOME = $sdkAnterior
}
