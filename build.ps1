param(
  [string]$Fpc = 'fpc',
  [string]$Version = '1.15-dev'
)

$ErrorActionPreference = 'Stop'

$FpcCmd           = (Get-Command $Fpc -ErrorAction Stop).Source
$env:COMPILE_DATE = (Get-Date).ToString('ddd, dd MMM yyyy "at" HH:mm:ss K')
$env:VERSION      = $Version
$FpcFlags         = @('-Sd', '-O2', '-gl', '-Sc', '-Sm', '-Sewn', '-vewnhi')

$Root    = Split-Path -Parent $MyInvocation.MyCommand.Path
$SrcDir  = Join-Path $Root 'src'
$LibDir  = Join-Path $Root 'lib'
$BinDir  = Join-Path $Root 'bin'
$Main    = Join-Path $SrcDir 'esn.pas'

# Vendored UnicodeVideo unit (lib/fpc/) — Windows driver.
$FpcVideo = @(
  "-Fi$LibDir\fpc\rtl-console\src\inc",
  "-Fu$LibDir\fpc\rtl-unicode\src\inc",
  "-Fi$LibDir\fpc\rtl-unicode\src\inc",
  "-Fu$LibDir\fpc\rtl-console\src\win"
)

if (!(Test-Path $BinDir)) {
  New-Item -ItemType Directory -Path $BinDir | Out-Null
}

& $FpcCmd @FpcFlags -B "-FU$BinDir" "-FE$BinDir" "-Fu$LibDir\rv" @FpcVideo $Main
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}
