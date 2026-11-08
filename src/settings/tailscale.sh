#!/usr/bin/env bash

set -e

TAILSCALE_BIN="$(command -v tailscale || true)"
if [[ -z "$TAILSCALE_BIN" ]]; then
  for candidate in \
    "/Applications/Tailscale.app/Contents/MacOS/Tailscale" \
    "/Applications/Tailscale.app/Contents/MacOS/tailscale" \
    "$HOME/Applications/Tailscale.app/Contents/MacOS/Tailscale"; do
    if [[ -x "$candidate" ]]; then
      TAILSCALE_BIN="$candidate"
      break
    fi
  done
fi

if [[ -z "$TAILSCALE_BIN" ]]; then
  echo "❌ Tailscale CLI was not found; IP forwarding was not changed." >&2
  echo "Install the app with: brew install --cask tailscale" >&2
  echo "Then open Tailscale, sign in, and run this setup again." >&2
  exit 127
fi

echo "==> 1. IP-Forwarding für macOS aktivieren..."
sudo sysctl -w net.inet.ip.forwarding=1

echo "==> 2. IP-Forwarding dauerhaft in /etc/sysctl.conf eintragen..."
if grep -q "net.inet.ip.forwarding=1" /etc/sysctl.conf 2>/dev/null; then
    echo "Eintrag bereits in /etc/sysctl.conf vorhanden."
else
    echo "net.inet.ip.forwarding=1" | sudo tee -a /etc/sysctl.conf
fi

echo "==> 3. Tailscale mit Subnet-Route (10.100.0.0/24) und Exit-Node starten..."
sudo "$TAILSCALE_BIN" up \
  --advertise-routes=10.100.0.0/24 \
  --advertise-exit-node \
  --accept-routes

echo "==> Fertig! Die Konfiguration wurde erfolgreich angewendet."
