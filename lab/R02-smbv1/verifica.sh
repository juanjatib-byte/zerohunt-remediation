#!/bin/bash

RUNNING_CONTAINERS=$(docker compose ps --services --filter "status=running" 2>/dev/null)

if [ -z "$RUNNING_CONTAINERS" ]; then
    echo "[ERROR] Nessun container attivo. Esegui prima: docker compose up -d"
    exit 1
fi

echo "[*] Controllo supporto SMBv1 (NT1) su target:445..."

OUTPUT=$(docker compose exec -T attacker smbclient -L //target -N --option="client min protocol=NT1" --option="client max protocol=NT1" 2>&1)

if echo "$OUTPUT" | grep -q "Sharename"; then
    echo "[VULNERABILE] Il server accetta connessioni con SMBv1 (NT1)!"
    exit 1
else
    echo "[OK] SMBv1 (NT1) rifiutato dal server. Configurazione sicura."
    exit 0
fi
