# ╭──────────────────────────────────────────────────────────╮
# │  Installation — Windows natif                             │
# │  Usage (PowerShell, depuis la racine du repo) :           │
# │    powershell -ExecutionPolicy Bypass -File install\windows.ps1
# │  Options :                                                │
# │    -BuildTools   installe aussi les Build Tools C++ de    │
# │                  Visual Studio (inutile si Visual Studio  │
# │                  est déjà installé, ex. pour Unreal)      │
# │    -Langages     installe .NET, JDK 21, Go et Rust        │
# ╰──────────────────────────────────────────────────────────╯
param(
    [switch]$BuildTools,
    [switch]$Langages
)
$ErrorActionPreference = "Continue"
$Repo = Split-Path -Parent $PSScriptRoot

function Say($msg) { Write-Host "`n==> $msg" -ForegroundColor Magenta }
function Install-Winget($id) {
    Write-Host "  - $id"
    winget install --id $id -e --accept-source-agreements --accept-package-agreements --silent | Out-Null
}

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Error "winget est introuvable. Installe « App Installer » depuis le Microsoft Store puis relance."
    exit 1
}

# ── 1. Logiciels ────────────────────────────────────────────
Say "Logiciels (winget)"
@(
    "Git.Git",
    "Neovim.Neovim",
    "wez.wezterm",
    "Microsoft.PowerShell",
    "JesseDuffield.lazygit",
    "BurntSushi.ripgrep.MSVC",
    "sharkdp.fd",
    "OpenJS.NodeJS.LTS",
    "Python.Python.3.12",
    "DEVCOM.JetBrainsMonoNerdFont"
) | ForEach-Object { Install-Winget $_ }

if ($Langages) {
    Say "Langages"
    @("Microsoft.DotNet.SDK.8", "EclipseAdoptium.Temurin.21.JDK", "GoLang.Go", "Rustlang.Rustup") |
        ForEach-Object { Install-Winget $_ }
}

# ── 2. Compilateur C (nécessaire pour les parseurs Treesitter) ──
Say "Compilateur C"
$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
$hasMsvc = (Test-Path $vswhere) -and (& $vswhere -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath)
if ($hasMsvc) {
    Write-Host "  Visual Studio C++ détecté."
} elseif ($BuildTools) {
    winget install --id Microsoft.VisualStudio.2022.BuildTools -e --accept-source-agreements --accept-package-agreements `
        --override "--quiet --wait --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"
} else {
    Write-Host "  Aucun compilateur C++ trouvé. Relance avec -BuildTools, ou installe Visual Studio avec le module C++." -ForegroundColor Yellow
}

# ── 3. Claude Code ──────────────────────────────────────────
Say "Claude Code"
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Invoke-RestMethod https://claude.ai/install.ps1 | Invoke-Expression
}

# ── 4. Liens vers la config ─────────────────────────────────
Say "Liens de configuration"
$nvimDir = Join-Path $env:LOCALAPPDATA "nvim"
if ((Test-Path $nvimDir) -and -not ((Get-Item $nvimDir).Attributes -band [IO.FileAttributes]::ReparsePoint)) {
    $backup = "$nvimDir.sauvegarde." + (Get-Date -Format "yyyyMMddHHmmss")
    Move-Item $nvimDir $backup
    Write-Host "  Ancienne config déplacée vers $backup"
}
if (-not (Test-Path $nvimDir)) {
    # Une jonction ne demande pas de droits administrateur.
    New-Item -ItemType Junction -Path $nvimDir -Target $Repo | Out-Null
}
Copy-Item (Join-Path $Repo "wezterm\wezterm.lua") (Join-Path $HOME ".wezterm.lua") -Force
Write-Host "  Neovim  : $nvimDir -> $Repo"
Write-Host "  WezTerm : $HOME\.wezterm.lua"

Write-Host @"

Terminé. Étapes suivantes :
  1. Ferme ce terminal et ouvre WezTerm (le PATH doit être rechargé).
  2. Installe le prompt PowerShell (repo séparé powershell-prompt).
  3. Lance « nvim » : plugins, LSP, formateurs, débogueurs et parseurs
     s'installent tout seuls (quelques minutes).
  4. Dans Neovim : « :NeoCodeium auth » pour les suggestions IA gratuites.
"@
