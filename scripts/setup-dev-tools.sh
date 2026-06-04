#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

add_to_bashrc_once() {
  local line="$1"

  if ! grep -Fxq "$line" "$HOME/.bashrc"; then
    echo "$line" >>"$HOME/.bashrc"
  fi
}

echo "Running from repo: $REPO_DIR"

echo "Installing apt packages..."
sudo apt update
sudo apt install -y \
  gcc \
  make \
  unzip \
  git \
  lazygit \
  ripgrep \
  curl \
  fzf \
  tmux

echo "Ensuring ~/.local/bin is in PATH..."
mkdir -p "$HOME/.local/bin"
add_to_bashrc_once 'export PATH="$PATH:$HOME/.local/bin"'

echo "Installing mise..."
curl https://mise.run | sh

add_to_bashrc_once 'eval "$("$HOME/.local/bin/mise" activate bash)"'

echo "Activating mise for current script session..."
eval "$("$HOME/.local/bin/mise" activate bash)"

echo "Installing Node LTS with mise..."
mise use -g node@lts

echo "Reloading ~/.bashrc after Node install..."
set +u
source "$HOME/.bashrc"
set -u

echo "Node version:"
node --version

echo "npm version:"
npm --version

echo "Installing starship..."
curl -sS https://starship.rs/install.sh | sh -s -- -y

add_to_bashrc_once 'eval "$(/usr/local/bin/starship init bash --print-full-init)"'

echo "Installing Neovim..."
cd /tmp
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz

sudo rm -rf /opt/nvim-linux-x86_64
sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz

add_to_bashrc_once 'export PATH="$PATH:/opt/nvim-linux-x86_64/bin"'

echo "Installing LazyVim starter..."
rm -rf "$HOME/.config/nvim"
git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"
rm -rf "$HOME/.config/nvim/.git"

echo "Installing Pi agent..."
curl -fsSL https://pi.dev/install.sh | sh

echo "Copying tmux config..."
cp "$REPO_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"

echo "Installing TPM..."
mkdir -p "$HOME/.tmux/plugins"

if [ ! -d "$HOME/.tmux/plugins/tpm/.git" ]; then
  git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
else
  git -C "$HOME/.tmux/plugins/tpm" pull --ff-only
fi

echo "Installing tmux plugins..."

TPM_SESSION="tpm-bootstrap-$$"

tmux new-session -d -s "$TPM_SESSION"

tmux set-environment -g TMUX_PLUGIN_MANAGER_PATH "$HOME/.tmux/plugins"
tmux source-file "$HOME/.tmux.conf"

"$HOME/.tmux/plugins/tpm/bin/install_plugins"

tmux source-file "$HOME/.tmux.conf"

tmux kill-session -t "$TPM_SESSION" 2>/dev/null || true

echo "Copying starship config..."
mkdir -p "$HOME/.config"
cp "$REPO_DIR/starship/starship.toml" "$HOME/.config/starship.toml"

echo "Copying Neovim config..."
rm -rf "$HOME/.config/nvim"
cp -r "$REPO_DIR/nvim" "$HOME/.config/nvim"

echo
set +u
source "$HOME/.bashrc"
set -u
echo "Done."
