#!/usr/bin/env bash
# Uso: ./run_scan_safe.sh 192.168.1.10
# Protegge da scansioni accidentali su IP pubblici controllando gli IP privati.

is_private_ip() {
  local ip="$1"
  # controlla 10.*, 172.16-31.*, 192.168.*, 127.*, localhost
  if [[ "$ip" =~ ^10\. ]] || \
     [[ "$ip" =~ ^192\.168\. ]] || \
     [[ "$ip" =~ ^127\. ]] || \
     [[ "$ip" =~ ^localhost$ ]] || \
     [[ "$ip" =~ ^172\.1[6-9]\. ]] || [[ "$ip" =~ ^172\.2[0-9]\. ]] || [[ "$ip" =~ ^172\.3[0-1]\. ]]; then
    return 0
  fi
  return 1
}

if [ -z "$1" ]; then
  echo "Usage: $0 <target-ip-or-hostname>"
  exit 1
fi

TARGET="$1"
OUTDIR="scans"
mkdir -p "$OUTDIR"
OUTFILE="$OUTDIR/scan_$(date +%Y%m%d_%H%M%S)_${TARGET//\//_}.nmap"

# Se sembra un IP, controlla che sia privato
if [[ "$TARGET" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  if ! is_private_ip "$TARGET"; then
    echo "WARNING: $TARGET non sembra un IP privato. Procedo solo se sei sicuro."
    read -p "Vuoi continuare? (y/N): " ans
    if [[ ! "$ans" =~ ^[Yy]$ ]]; then
      echo "Annullato."
      exit 2
    fi
  fi
else
  echo "Target non è un IP numerico (hostname). Assicurati di avere autorizzazione prima di scansionare."
  read -p "Procedere? (y/N): " ans
  if [[ ! "$ans" =~ ^[Yy]$ ]]; then
    echo "Annullato."
    exit 2
  fi
fi

echo "[*] Eseguo nmap su $TARGET, output -> $OUTFILE"
nmap -sS -sV -O -p1-1024 -T3 "$TARGET" -oN "$OUTFILE"

echo "[*] Fatto. File: $OUTFILE"
