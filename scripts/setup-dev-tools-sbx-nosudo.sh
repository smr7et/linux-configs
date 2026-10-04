#!/usr/bin/env bash
# Sudo-less variant of setup-dev-tools-sbx.sh. Everything installs under $HOME
# and each tool is skipped if it is already present.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

LOCAL_BIN="$HOME/.local/bin"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

SUMMARY=()

add_to_bashrc_once() {
  local line="$1"

  touch "$HOME/.bashrc"
  if ! grep -Fxq "$line" "$HOME/.bashrc"; then
    echo "$line" >>"$HOME/.bashrc"
  fi
}

have() {
  command -v "$1" >/dev/null 2>&1
}

note() {
  SUMMARY+=("$1")
}

# Prints the tag of the latest GitHub release for owner/repo (without leading v).
github_latest_version() {
  local json
  json="$(curl -fsSL "https://api.github.com/repos/$1/releases/latest")"
  grep '"tag_name"' <<<"$json" | head -n1 | sed -E 's/.*"v?([^"]+)".*/\1/'
}

echo "Running from repo: $REPO_DIR"

echo "Ensuring ~/.local/bin is in PATH..."
mkdir -p "$LOCAL_BIN" "$HOME/.local/opt"
add_to_bashrc_once 'export PATH="$PATH:$HOME/.local/bin"'
export PATH="$LOCAL_BIN:$PATH"

echo "Checking system packages (no sudo available, not installing)..."
for tool in gcc make fzf git curl unzip zip telnet ip rg; do
  if have "$tool"; then
    note "ok          $tool (system)"
  elif [ "$tool" = "fzf" ]; then
    note "pending     $tool (installed from release below)"
  else
    note "NEEDS SUDO  $tool (apt install required)"
  fi
done

echo "Installing Rust toolchain with rustup..."
if have rustup || [ -x "$HOME/.cargo/bin/rustup" ]; then
  note "skipped     rustup (already installed)"
else
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
  note "installed   rustup"
fi
# shellcheck disable=SC1091
source "$HOME/.cargo/env"
rustup update stable
add_to_bashrc_once 'export PATH="$PATH:$HOME/.cargo/bin"'

echo "Installing cargo-binstall (prebuilt, no compiler needed)..."
if have cargo-binstall; then
  note "skipped     cargo-binstall (already installed)"
else
  curl -fsSL https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | bash
  note "installed   cargo-binstall"
fi

echo "Installing atuin..."
if have atuin; then
  note "skipped     atuin (already installed)"
else
  if ! cargo binstall -y atuin; then
    curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh
  fi
  note "installed   atuin"
fi

echo "Installing lazygit..."
if have lazygit; then
  note "skipped     lazygit (already installed)"
else
  version="$(github_latest_version jesseduffield/lazygit)"
  curl -fsSL -o "$TMP_DIR/lazygit.tar.gz" \
    "https://github.com/jesseduffield/lazygit/releases/download/v${version}/lazygit_${version}_Linux_x86_64.tar.gz"
  tar -C "$TMP_DIR" -xzf "$TMP_DIR/lazygit.tar.gz" lazygit
  install -m 0755 "$TMP_DIR/lazygit" "$LOCAL_BIN/lazygit"
  note "installed   lazygit $version"
fi

echo "Installing fzf..."
if have fzf; then
  note "skipped     fzf (already installed)"
else
  version="$(github_latest_version junegunn/fzf)"
  curl -fsSL -o "$TMP_DIR/fzf.tar.gz" \
    "https://github.com/junegunn/fzf/releases/download/v${version}/fzf-${version}-linux_amd64.tar.gz"
  tar -C "$LOCAL_BIN" -xzf "$TMP_DIR/fzf.tar.gz" fzf
  note "installed   fzf $version"
fi

echo "Setting up mise and Node..."
MISE_BIN="$(command -v mise || true)"
if [ -z "$MISE_BIN" ]; then
  curl -fsSL https://mise.run | sh
  MISE_BIN="$LOCAL_BIN/mise"
  note "installed   mise"
else
  note "skipped     mise (already installed)"
fi
add_to_bashrc_once 'eval "$("$HOME/.local/bin/mise" activate bash)"'
export PATH="$HOME/.local/share/mise/shims:$PATH"

if have node; then
  note "skipped     node $(node --version) (global mise pin left unchanged)"
else
  "$MISE_BIN" install node@lts
  "$MISE_BIN" use -g node@lts
  "$MISE_BIN" reshim 2>/dev/null || true
  hash -r
  note "installed   node $(node --version)"
fi
node --version
npm --version

echo "Installing starship..."
if have starship; then
  note "skipped     starship (already installed)"
else
  curl -sS https://starship.rs/install.sh | sh -s -- --yes --bin-dir "$LOCAL_BIN"
  note "installed   starship"
fi
add_to_bashrc_once 'eval "$(starship init bash)"'

echo "Installing Neovim..."
if have nvim; then
  note "skipped     nvim (already installed)"
else
  curl -fsSL -o "$TMP_DIR/nvim.tar.gz" \
    https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
  rm -rf "$HOME/.local/opt/nvim-linux-x86_64"
  tar -C "$HOME/.local/opt" -xzf "$TMP_DIR/nvim.tar.gz"
  ln -sf "$HOME/.local/opt/nvim-linux-x86_64/bin/nvim" "$LOCAL_BIN/nvim"
  note "installed   nvim"
fi

echo "Copying Neovim config..."
rm -rf "$HOME/.config/nvim"
mkdir -p "$HOME/.config"
cp -r "$REPO_DIR/nvim" "$HOME/.config/nvim"
note "installed   nvim config"

echo "Installing Pi agent..."
if have pi; then
  note "skipped     pi (already installed)"
else
  curl -fsSL https://pi.dev/install.sh | "$MISE_BIN" exec node -- sh
  note "installed   pi"
fi

echo "Installing Herdr multiplexer..."
if have herdr; then
  note "skipped     herdr (already installed)"
else
  curl -fsSL https://herdr.dev/install.sh | sh
  note "installed   herdr"
fi

echo
echo "Summary:"
printf '  %s\n' "${SUMMARY[@]}"
echo "Done. Open a new shell (or 'source ~/.bashrc') to pick up PATH changes."
