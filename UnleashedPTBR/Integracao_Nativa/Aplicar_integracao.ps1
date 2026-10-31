param(
    [string]$PastaDoJogo,
    [switch]$Restaurar
)
$ErrorActionPreference = 'Stop'
function Get-BytesHash([byte[]]$Bytes) {
    $Hasher = [System.Security.Cryptography.SHA256]::Create()
    try { return ([BitConverter]::ToString($Hasher.ComputeHash($Bytes))).Replace('-', '').ToLowerInvariant() }
    finally { $Hasher.Dispose() }
}
if (-not $PastaDoJogo) {
    Add-Type -AssemblyName System.Windows.Forms
    $Dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $Dialog.Description = 'Selecione a pasta do Unleashed Recompiled'
    if ($Dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { return }
    $PastaDoJogo = $Dialog.SelectedPath
    $Dialog.Dispose()
}
$GameRoot = [System.IO.Path]::GetFullPath($PastaDoJogo)
$Target = Join-Path $GameRoot 'Sonic unleashed.exe'
$Backup = "$Target.ptbr-launcher.bak"
$Temporary = "$Target.ptbr-launcher.tmp"
if (-not (Test-Path -LiteralPath $Target -PathType Leaf)) { throw 'Sonic unleashed.exe nao encontrado na pasta selecionada.' }
$PatchPath = Join-Path $PSScriptRoot 'launcher_ptbr.patch.json.gz'
$InputStream = [System.IO.File]::OpenRead($PatchPath)
$Gzip = New-Object System.IO.Compression.GZipStream($InputStream, [System.IO.Compression.CompressionMode]::Decompress)
$Reader = New-Object System.IO.StreamReader($Gzip, [System.Text.Encoding]::UTF8)
try { $Patch = $Reader.ReadToEnd() | ConvertFrom-Json }
finally { $Reader.Dispose(); $Gzip.Dispose(); $InputStream.Dispose() }
[byte[]]$Before = [System.IO.File]::ReadAllBytes($Target)
$BeforeHash = Get-BytesHash $Before
if ($Restaurar) {
    if (($Patch.patched_hashes -notcontains $BeforeHash)) { throw 'O executavel mudou. A restauracao automatica foi interrompida para preservar esta versao.' }
    if (-not (Test-Path -LiteralPath $Backup -PathType Leaf)) { throw 'Backup da versao anterior nao encontrado.' }
    [byte[]]$Result = [System.IO.File]::ReadAllBytes($Backup)
    $Expected = Get-BytesHash $Result
    if (-not @($Patch.variants | Where-Object { $_.source_sha256 -eq $Expected }).Count) { throw 'O backup nao corresponde a uma versao reconhecida.' }
} else {
    if (($Patch.patched_hashes -contains $BeforeHash)) { Write-Output 'A traducao do instalador ja esta aplicada.'; return }
    $Variant = @($Patch.variants | Where-Object { $_.source_sha256 -eq $BeforeHash -and $_.source_length -eq $Before.Length })
    if ($Variant.Count -ne 1) { throw 'Esta versao do executavel nao e compativel com este pacote. Nenhum arquivo foi alterado.' }
    [byte[]]$Result = New-Object byte[] ([int]$Variant[0].patched_length)
    [Array]::Copy($Before, $Result, [Math]::Min($Before.Length, $Result.Length))
    foreach ($Write in $Variant[0].writes) {
        [byte[]]$Data = [Convert]::FromBase64String($Write.data)
        if ($Write.offset -lt 0 -or $Write.offset + $Data.Length -gt $Result.Length) { throw 'Intervalo invalido no pacote.' }
        [Array]::Copy($Data, 0, $Result, [int]$Write.offset, $Data.Length)
    }
    $Expected = $Variant[0].patched_sha256
    if ((Get-BytesHash $Result) -ne $Expected) { throw 'A verificacao da traducao falhou. Nenhum arquivo foi alterado.' }
}
# Exclusive access prevents replacement while the game is using its executable.
$Handle = [System.IO.File]::Open($Target, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
$Handle.Dispose()
if (-not $Restaurar) {
    if (Test-Path -LiteralPath $Backup) {
        $SavedHash = Get-BytesHash ([System.IO.File]::ReadAllBytes($Backup))
        if (-not @($Patch.variants | Where-Object { $_.source_sha256 -eq $SavedHash }).Count) { throw 'Ja existe um backup de outra versao. Ele foi preservado e a instalacao foi interrompida.' }
    } else { [System.IO.File]::WriteAllBytes($Backup, $Before) }
}
if (Test-Path -LiteralPath $Temporary) { throw 'Existe um arquivo temporario de outra instalacao. Nenhum arquivo foi substituido.' }
try {
    [System.IO.File]::WriteAllBytes($Temporary, $Result)
    if ((Get-BytesHash ([System.IO.File]::ReadAllBytes($Temporary))) -ne $Expected) { throw 'Falha ao verificar o arquivo temporario.' }
    if ((Get-BytesHash ([System.IO.File]::ReadAllBytes($Target))) -ne $BeforeHash) { throw 'O executavel mudou durante a preparacao.' }
    [System.IO.File]::Replace($Temporary, $Target, [System.Management.Automation.Language.NullString]::Value)
    if ((Get-BytesHash ([System.IO.File]::ReadAllBytes($Target))) -ne $Expected) { throw 'Falha na verificacao final.' }
} finally {
    if (Test-Path -LiteralPath $Temporary) { Remove-Item -LiteralPath $Temporary }
}
if ($Restaurar) { Write-Output 'Versao anterior restaurada.' }
else { Write-Output 'Integracao instalada. Configuracoes e conquistas seguem o mod PT-BR apos reiniciar.' }
