#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
plugin_src="$repo_dir/hermes-status"
plugin_dst="$HOME/.config/noctalia/plugins/hermes-status"
check_dst="$HOME/.config/noctalia/hermes-status-check"
hook_dst="$HOME/.local/bin/hermes-status-hook"
attention_dst="$HOME/.local/bin/hermes-attention"

if [[ ! -d "$plugin_src" ]]; then
  echo "error: hermes-status plugin directory not found next to install.sh" >&2
  exit 1
fi

mkdir -p "$HOME/.config/noctalia/plugins" "$HOME/.config/noctalia" "$HOME/.local/bin"

ln -sfn "$plugin_src" "$plugin_dst"
install -m 755 "$repo_dir/hermes-status-check" "$check_dst"
install -m 755 "$repo_dir/hermes-status-hook" "$hook_dst"
install -m 755 "$repo_dir/hermes-attention" "$attention_dst"

echo "Installed noctalia-hermes:"
echo "  plugin:          $plugin_dst -> $plugin_src"
echo "  status checker:  $check_dst"
echo "  hook script:     $hook_dst"
echo "  attention tool:  $attention_dst"

case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *)
    echo
    echo "Note: ~/.local/bin is not currently in PATH. Add this to your shell profile:"
    echo '  export PATH="$HOME/.local/bin:$PATH"'
    ;;
esac

echo
echo "Next steps:"
echo "  1. Add the hooks snippet from README.md to ~/.hermes/config.yaml"
echo "  2. Run: hermes hooks doctor"
echo "  3. Restart noctalia-shell to load the plugin"
