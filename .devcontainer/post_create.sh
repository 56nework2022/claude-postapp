npx --yes playwright install-deps chromium

# --- Flutter SDK setup (for the "撮影用ポスト画面メーカー" Flutter app) ---
set -e

FLUTTER_VERSION="3.44.8"
FLUTTER_HOME="/opt/flutter"

if [ ! -d "$FLUTTER_HOME" ]; then
  sudo apt-get update -qq
  sudo apt-get install -y -qq clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev

  TMP_ARCHIVE="$(mktemp -d)/flutter_linux.tar.xz"
  curl -sL -o "$TMP_ARCHIVE" \
    "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
  sudo tar -xf "$TMP_ARCHIVE" -C /opt/
  sudo chown -R "$(whoami)":"$(whoami)" "$FLUTTER_HOME"
  rm -f "$TMP_ARCHIVE"
fi

for RC in "$HOME/.bashrc" "$HOME/.profile"; do
  grep -q '/opt/flutter/bin' "$RC" 2>/dev/null || echo 'export PATH="$PATH:/opt/flutter/bin"' >> "$RC"
done

export PATH="$PATH:/opt/flutter/bin"
flutter config --no-analytics >/dev/null 2>&1 || true
flutter precache --linux >/dev/null 2>&1 || true
