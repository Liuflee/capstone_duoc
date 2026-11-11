param([switch]$Preparar)
$ErrorActionPreference = 'Stop'
Push-Location $PSScriptRoot
try {
    if (-not (Test-Path -LiteralPath '.venv\Scripts\python.exe')) {
        python -m venv .venv
        if ($LASTEXITCODE -ne 0) { throw 'Se necesita Python 3.11 o superior.' }
        $Preparar = $true
    }
    if ($Preparar) {
        & '.\.venv\Scripts\python.exe' -m pip install -r requirements.txt
        if ($LASTEXITCODE -ne 0) { throw 'No se pudieron instalar las dependencias.' }
        & '.\.venv\Scripts\python.exe' -c "import servidor, numpy as np; servidor.transcribir(np.zeros(16000, dtype=np.float32)); print('Whisper preparado.')"
        if ($LASTEXITCODE -ne 0) { throw 'No se pudo preparar el modelo Whisper.' }
    }
    Write-Host 'Servicio de voz: http://127.0.0.1:8765. Deja esta ventana abierta.'
    & '.\.venv\Scripts\python.exe' -m uvicorn servidor:app --host 127.0.0.1 --port 8765 --no-access-log
} finally {
    Pop-Location
}
