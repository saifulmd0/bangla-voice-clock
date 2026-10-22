# Builds the Microsoft Store package from the Windows app.
#
#   tool/windows/make_msix.ps1 -App "Bangla Voice Clock" -Version 1.0.0 -Out x.msix
#
# The package is unsigned: the Store signs what it publishes. To install it
# on a test PC, sign it with a certificate whose subject matches the
# manifest's Publisher.
param(
  [Parameter(Mandatory)] [string] $App,
  [Parameter(Mandatory)] [string] $Version,
  [Parameter(Mandatory)] [string] $Out
)
$ErrorActionPreference = 'Stop'

# The newest Windows SDK that has the packaging tools.
$kit = Get-ChildItem "${env:ProgramFiles(x86)}\Windows Kits\10\bin\10.*\x64\makeappx.exe" |
  Sort-Object { [version]$_.Directory.Parent.Name } -Descending |
  Select-Object -First 1 | ForEach-Object Directory
$makepri = Join-Path $kit.FullName 'makepri.exe'
$makeappx = Join-Path $kit.FullName 'makeappx.exe'

$stage = Join-Path ([IO.Path]::GetTempPath()) 'bvc-msix'
Remove-Item -Recurse -Force $stage -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $stage | Out-Null
Copy-Item -Recurse "$App\*" $stage
Copy-Item -Recurse windows\msix\Assets (Join-Path $stage 'Assets')
# The Store wants four parts, the last one 0.
(Get-Content -Raw windows\msix\AppxManifest.xml).Replace('@VERSION@', "$Version.0") |
  Set-Content -Encoding utf8 (Join-Path $stage 'AppxManifest.xml')

# The resource index lets Windows pick each logo's size and scale.
Push-Location $stage
& $makepri createconfig /cf priconfig.xml /dq en-US /o
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $makepri new /pr . /cf priconfig.xml /of resources.pri /o
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Remove-Item priconfig.xml
Pop-Location

& $makeappx pack /o /d $stage /p $Out
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
