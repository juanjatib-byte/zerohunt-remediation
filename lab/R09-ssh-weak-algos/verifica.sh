#!/bin/bash

RUNNING_CONTAINERS=$(docker compose ps --services --filter "status=running" 2>/dev/null)

if [ -z "$RUNNING_CONTAINERS" ]; then
    echo "[ERROR] Nessun container attivo. Esegui prima: docker compose --profile vulnerabile up -d (o corretto)"
    exit 1
fi

echo "[*] Controllo algoritmi SSH deboli su target:22..."

OUTPUT=$(docker compose exec -T attacker nmap -p 22 --script ssh2-enum-algos target 2>&1)

if echo "$OUTPUT" | grep -Eq "diffie-hellman-group1-sha1|aes128-cbc|3des-cbc|hmac-sha1"; then
    echo "[VULNERABILE] Il server SSH accetta algoritmi deboli (CBC / SHA-1 / group1)!"
    exit 1
else
    echo "[OK] Nessun algoritmo SSH debole rilevato. Configurazione sicura."
    exit 0
fi
