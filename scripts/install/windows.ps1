# Prerequis du projet sous Windows 10/11, a lancer une fois, avant le premier jour.
# Dans PowerShell ouvert EN ADMINISTRATEUR (clic droit > Executer en tant qu'administrateur) :
#   irm https://raw.githubusercontent.com/Hackathon-Givaudan-Hetic/hackathon-app/develop/scripts/install/windows.ps1 | iex
# Installe ce qui manque (WSL 2 + Ubuntu, Docker Desktop, VS Code, Ollama), ne touche pas a ce qui est la.
# Peut etre relance sans risque, par exemple apres le redemarrage demande.
# Fichier volontairement sans accents : PowerShell 5.1 les lit mal dans un script telecharge.

$ErrorActionPreference = 'Stop'
$redemarrer = $false

function Etape($texte) { Write-Host "`n==> $texte" -ForegroundColor Cyan }

# 0. Droits administrateur : WSL et Docker en ont besoin
$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $admin) {
  Write-Host "Relancez PowerShell en administrateur (clic droit > Executer en tant qu'administrateur)." -ForegroundColor Red
  return
}
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
  Write-Host "winget manque : installez 'App Installer' depuis le Microsoft Store, puis relancez." -ForegroundColor Red
  return
}

# 1. WSL 2 et Ubuntu : le projet sera clone et lance dans Linux, pas dans C:\
Etape "WSL 2 + Ubuntu"
$distros = ((wsl.exe -l -q 2>$null) -join "`n") -replace "`0", ''
if ($distros -notmatch 'Ubuntu') {
  wsl.exe --install -d Ubuntu --no-launch
  $redemarrer = $true
  Write-Host "Ubuntu installe : un redemarrage sera necessaire."
} else {
  wsl.exe --set-default-version 2 | Out-Null
  # Ubuntu par defaut : sinon "wsl" peut ouvrir "docker-desktop", la distribution interne de Docker
  $ubuntu = ($distros -split "`n" | Where-Object { $_ -match '^Ubuntu' } | Select-Object -First 1).Trim()
  wsl.exe --set-default $ubuntu | Out-Null
  Write-Host "ok : $ubuntu present, distribution par defaut"
}

# 2. Logiciels Windows : inventaire d'abord, installation par winget seulement si absent
# Premier chemin existant parmi une liste (le programme est-il deja sur le disque ?)
function Trouver($chemins) {
  $chemins | Where-Object { Test-Path $_ } | Select-Object -First 1
}

# Renvoie $true si le logiciel vient d'etre installe, $false s'il etait deja la
function Installer($id, $nom, $chemins) {
  # 1. Sur le disque : couvre aussi une installation faite a la main, hors winget
  $trouve = Trouver $chemins
  if ($trouve) {
    Write-Host "ok : $nom deja installe ($trouve)"
    return $false
  }
  # 2. Connu de winget
  winget list --id $id -e --accept-source-agreements | Out-Null
  if ($LASTEXITCODE -eq 0) {
    Write-Host "ok : $nom deja installe (winget)"
    return $false
  }
  Write-Host "Installation de $nom..."
  winget install --id $id -e --silent --accept-package-agreements --accept-source-agreements | Out-Host
  return $true
}

$cheminsDocker = @("$env:ProgramFiles\Docker\Docker\Docker Desktop.exe")
$cheminsCode = @(
  "$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin\code.cmd",
  "$env:ProgramFiles\Microsoft VS Code\bin\code.cmd"
)
$cheminsOllama = @(
  "$env:LOCALAPPDATA\Programs\Ollama\ollama.exe",
  "$env:ProgramFiles\Ollama\ollama.exe"
)

Etape "Docker Desktop"
# Docker Desktop demande une reconnexion apres sa premiere installation
if (Installer 'Docker.DockerDesktop' 'Docker Desktop' $cheminsDocker) { $redemarrer = $true }

Etape "VS Code et ses extensions"
Installer 'Microsoft.VisualStudioCode' 'VS Code' $cheminsCode | Out-Null
$code = Trouver $cheminsCode
if ($code) {
  # WSL : ouvrir un dossier Linux dans VS Code. Dev Containers : le dev container du projet.
  & $code --install-extension ms-vscode-remote.remote-wsl --force | Out-Null
  & $code --install-extension ms-vscode-remote.remote-containers --force | Out-Null
  Write-Host "ok : extensions WSL et Dev Containers"
} else {
  Write-Host "!! VS Code introuvable : installez les extensions 'WSL' et 'Dev Containers' a la main." -ForegroundColor Yellow
}

Etape "Ollama et le modele de dev"
Installer 'Ollama.Ollama' 'Ollama' $cheminsOllama | Out-Null
$ollama = Trouver $cheminsOllama
if ($ollama) {
  # Ollama tourne en arriere-plan (icone pres de l'horloge) ; on le demarre s'il ne repond pas
  try { Invoke-WebRequest -UseBasicParsing http://localhost:11434 -TimeoutSec 3 | Out-Null }
  catch { Start-Process $ollama -ArgumentList 'serve' -WindowStyle Hidden; Start-Sleep 5 }
  & $ollama pull llama3.2:1b
  Write-Host "ok : modele llama3.2:1b"
} else {
  Write-Host "!! Ollama introuvable : apres redemarrage, dans PowerShell : ollama pull llama3.2:1b" -ForegroundColor Yellow
}

Etape "Termine"
if ($redemarrer) {
  Write-Host "1. REDEMARREZ l'ordinateur." -ForegroundColor Yellow
}
Write-Host "2. Lancez Docker Desktop, acceptez les conditions, et verifiez :"
Write-Host "   Settings > General > 'Use the WSL 2 based engine' coche"
Write-Host "   Settings > Resources > WSL integration > Ubuntu active"
Write-Host "3. Ouvrez 'Ubuntu' depuis le menu Demarrer (premiere fois : choisissez un nom d'utilisateur et un mot de passe)."
Write-Host "4. Suite : README.md, section 'Windows', etape 3."
