#!/bin/bash

RUNNING_CONTAINERS=$(docker compose ps --services --filter "status=running" 2>/dev/null)

if [ -z "$RUNNING_CONTAINERS" ]; then
    echo "[ERROR] Nessun container attivo. Esegui prima: docker compose --profile vulnerabile up -d (o corretto)"
    exit 1
fi

echo "[*] Controllo autenticazione SSH via password per root su target:22..."

OUTPUT=$(docker compose exec -T attacker ssh -o PreferredAuthentications=none -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5 root@target 2>&1)

if echo "$OUTPUT" | grep -q "password"; then
    echo "[VULNERABILE] Il server SSH consente l'autenticazione con password (anche per root)!"
    exit 1
elif echo "$OUTPUT" | grep -q "Permission denied (publickey)"; then
    echo "[OK] Autenticazione con password disabilitata (solo publickey). Configurazione sicura."
    exit 0
else
    echo "[ERROR] Risposta inattesa dal server SSH: $OUTPUT"
    exit 1
fi
