#!/bin/bash

RUNNING_CONTAINERS=$(docker compose ps --services --filter "status=running" 2>/dev/null)

if [ -z "$RUNNING_CONTAINERS" ]; then
    echo "[ERROR] Nessun container attivo. Esegui prima: docker compose up -d"
    exit 1
fi

echo "[*] Controllo trasferimento di zona DNS (AXFR) su target per zerohunt.local..."

# Esegue la richiesta AXFR dal container attacker tramite dig
OUTPUT=$(docker compose exec -T attacker dig @target zerohunt.local AXFR +noall +answer 2>&1)

# Se il trasferimento ha successo, dig restituisce i record della zona (es. SOA o record A interni)
if echo "$OUTPUT" | grep -q "IN[[:space:]]*SOA"; then
    echo "[VULNERABILE] Trasferimento di zona AXFR permesso! Record estratti:"
    echo "$OUTPUT"
    exit 1
else
    echo "[OK] Trasferimento di zona AXFR rifiutato. Configurazione sicura."
    exit 0
fi
