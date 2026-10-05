#!/usr/bin/env bash
# ╭──────────────────────────────────────────────────────────╮
# │  Installation — Linux et WSL                              │
# │  Arch · Fedora · Debian/Ubuntu                            │
# │  Usage : ./install/linux.sh   (depuis la racine du repo)  │
# ╰──────────────────────────────────────────────────────────╯
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NVIM_VERSION="stable"
IS_WSL=false
grep -qi microsoft /proc/version 2>/dev/null && IS_WSL=true

say() { printf '\n\033[1;35m==> %s\033[0m\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

# ── 1. Paquets système ──────────────────────────────────────
say "Paquets système"
if have pacman; then
  sudo pacman -S --needed --noconfirm git curl unzip tar gzip gcc make ripgrep fd lazygit \
    nodejs npm python python-pip zsh tree-sitter-cli
  $IS_WSL || sudo pacman -S --needed --noconfirm wezterm
elif have dnf; then
  sudo dnf install -y git curl unzip tar gzip gcc gcc-c++ make ripgrep fd-find nodejs npm \
    python3 python3-pip zsh
  sudo dnf copr enable -y atim/lazygit && sudo dnf install -y lazygit || true
  $IS_WSL || { sudo dnf copr enable -y wezfurlong/wezterm-nightly && sudo dnf install -y wezterm || true; }
elif have apt-get; then
  sudo apt-get update
  sudo apt-get install -y git curl unzip tar gzip build-essential ripgrep fd-find nodejs npm \
    python3 python3-pip python3-venv zsh fontconfig
  # Ubuntu nomme fd « fdfind » : on crée l'alias attendu.
  mkdir -p "$HOME/.local/bin"
  have fd || ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
  if ! have lazygit; then
    LG=$(curl -s https://api.github.com/repos/jesseduffield/lazygit/releases/latest | grep -Po '"tag_name": "v\K[^"]*')
    curl -sLo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LG}/lazygit_${LG}_Linux_x86_64.tar.gz"
    tar xf /tmp/lazygit.tar.gz -C "$HOME/.local/bin" lazygit
  fi
  if ! $IS_WSL && ! have wezterm; then
    curl -fsSL https://apt.fury.io/wez/gpg.key | sudo gpg --yes --dearmor -o /usr/share/keyrings/wezterm-fury.gpg
    echo 'deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' | sudo tee /etc/apt/sources.list.d/wezterm.list
    sudo apt-get update && sudo apt-get install -y wezterm
  fi
else
  echo "Gestionnaire de paquets non reconnu : installe à la main git, curl, gcc, make, ripgrep, fd, lazygit, nodejs, python3, zsh."
fi

# ── 2. Neovim (version officielle récente, les dépôts sont souvent en retard) ──
say "Neovim"
if ! have nvim || ! nvim --headless -c 'if has("nvim-0.12") | qa | else | cq | endif' 2>/dev/null; then
  mkdir -p "$HOME/.local/opt" "$HOME/.local/bin"
  curl -sLo /tmp/nvim.tar.gz "https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim-linux-x86_64.tar.gz"
  rm -rf "$HOME/.local/opt/nvim-linux-x86_64"
  tar xzf /tmp/nvim.tar.gz -C "$HOME/.local/opt"
  ln -sf "$HOME/.local/opt/nvim-linux-x86_64/bin/nvim" "$HOME/.local/bin/nvim"
fi

# ── 3. Police ───────────────────────────────────────────────
if ! $IS_WSL; then
  say "Police JetBrainsMono Nerd Font"
  if ! fc-list 2>/dev/null | grep -qi "JetBrainsMono Nerd"; then
    mkdir -p "$HOME/.local/share/fonts/JetBrainsMono"
    curl -sLo /tmp/jbm.zip https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
    unzip -oq /tmp/jbm.zip -d "$HOME/.local/share/fonts/JetBrainsMono"
    fc-cache -f >/dev/null
  fi
else
  echo "WSL : la police s'installe côté Windows (voir install/windows.ps1)."
fi

# ── 4. Claude Code ──────────────────────────────────────────
say "Claude Code"
have claude || curl -fsSL https://claude.ai/install.sh | bash

# ── 5. Oh My Zsh + thème ────────────────────────────────────
say "Oh My Zsh"
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi
mkdir -p "$HOME/.oh-my-zsh/custom/themes"
cp "$REPO/zsh/catppuccin.zsh-theme" "$HOME/.oh-my-zsh/custom/themes/"
sed -i 's/^ZSH_THEME=.*/ZSH_THEME="catppuccin"/' "$HOME/.zshrc"
grep -q '.local/bin' "$HOME/.zshrc" || echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
[ "$(basename "${SHELL:-}")" = "zsh" ] || chsh -s "$(command -v zsh)" || true

# ── 6. Liens vers la config ─────────────────────────────────
say "Liens de configuration"
mkdir -p "$HOME/.config"
if [ -e "$HOME/.config/nvim" ] && [ ! -L "$HOME/.config/nvim" ]; then
  mv "$HOME/.config/nvim" "$HOME/.config/nvim.sauvegarde.$(date +%s)"
fi
ln -sfn "$REPO" "$HOME/.config/nvim"
$IS_WSL || ln -sf "$REPO/wezterm/wezterm.lua" "$HOME/.wezterm.lua"

# ── 7. Outils optionnels (selon tes langages) ───────────────
cat <<'EOF'

Terminé. Outils à installer selon tes besoins :
  • Rust          : curl https://sh.rustup.rs -sSf | sh
  • Go            : paquet « go » / « golang » de ta distribution
  • C# / Unity    : SDK .NET 8 ou plus (paquet « dotnet-sdk-8.0 »)
  • Java          : JDK 21 (paquet « openjdk-21-jdk » / « java-21-openjdk »)

Premier lancement : ouvre `nvim`. Les plugins, serveurs LSP, formateurs,
débogueurs et parseurs s'installent tout seuls (quelques minutes).
Puis :  `:NeoCodeium auth`  pour activer les suggestions IA gratuites.
EOF
