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
  tmux \
  cargo

cargo install cargo-binstall
cargo binstall zellij

mkdir -p ~/.config/zellij

cat >~/.config/zellij/config.kdl <<'EOF'
  default_shell "/bin/bash"
EOF

echo "Ensuring ~/.local/bin is in PATH..."
mkdir -p "$HOME/.local/bin"
add_to_bashrc_once 'export PATH="$PATH:$HOME/.local/bin"'

MISE_BIN="$HOME/.local/bin/mise"

echo "Installing mise..."
curl https://mise.run | sh

add_to_bashrc_once 'eval "$("$HOME/.local/bin/mise" activate bash)"'

echo "Activating mise for this script session..."
export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"

set +u
eval "$("$MISE_BIN" activate bash)"
set -u

echo "Installing Node LTS with mise..."
"$MISE_BIN" install node@lts
"$MISE_BIN" use -g node@lts

echo "Refreshing mise shims..."
"$MISE_BIN" reshim node@lts 2>/dev/null || "$MISE_BIN" reshim 2>/dev/null || true

hash -r

echo "Checking Node through mise..."
"$MISE_BIN" exec node@lts -- node --version
"$MISE_BIN" exec node@lts -- npm --version

echo "Node version:"
node --version

echo "npm version:"
npm --version

echo "Installing starship..."
curl -sS https://starship.rs/install.sh | sh -s -- --yes --bin-dir "$HOME/.local/bin"

add_to_bashrc_once 'eval "$(starship init bash)"'

echo "Installing Neovim..."
cd /tmp
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz

rm -rf "$HOME/.local/opt/nvim-linux-x86_64"
mkdir -p "$HOME/.local/opt" "$HOME/.local/bin"

tar -C "$HOME/.local/opt" -xzf nvim-linux-x86_64.tar.gz
ln -sf "$HOME/.local/opt/nvim-linux-x86_64/bin/nvim" "$HOME/.local/bin/nvim"

add_to_bashrc_once 'export PATH="$PATH:$HOME/.local/bin"'

echo "Installing LazyVim starter..."
rm -rf "$HOME/.config/nvim"
git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"
rm -rf "$HOME/.config/nvim/.git"

echo "Installing Pi agent..."
curl -fsSL https://pi.dev/install.sh | "$MISE_BIN" exec node@lts -- sh

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

add_to_bashrc_once '# UTF-8 for tmux / nvim / Nerd Font glyph width'
add_to_bashrc_once 'export LANG=C.UTF-8'
add_to_bashrc_once 'export LC_CTYPE=C.UTF-8'
add_to_bashrc_once 'unset LC_ALL'

cat >>~/.tmux.conf <<'EOF'

# Terminal compatibility
set -g default-terminal "tmux-256color"
set -as terminal-overrides ",xterm-256color:Tc"
set -as terminal-overrides ",tmux-256color:Tc"
set -g fill-character ' '
EOF

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
