#!/bin/bash

echo "[*] Controllo autenticazione Redis su target:6379..."

# Esegue il comando dalla rete tramite il container attacker
OUTPUT=$(docker compose exec -T attacker redis-cli -h target ping 2>&1)

echo "[*] Risposta ricevuta: $OUTPUT"

if echo "$OUTPUT" | grep -q "NOAUTH"; then
    echo "[OK] Redis richiede autenticazione. Configurazione sicura."
    exit 0
else
    echo "[VULNERABILE] Redis risponde senza autenticazione!"
    exit 1
fi
