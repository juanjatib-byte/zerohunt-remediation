#!/bin/bash

RUNNING_CONTAINERS=$(docker compose ps --services --filter "status=running" 2>/dev/null)

if [ -z "$RUNNING_CONTAINERS" ]; then
    echo "[ERROR] Nessun container attivo. Esegui prima: docker compose up -d"
    exit 1
fi


echo "[*] Controllo community SNMP predefinita ('public') su target:161..."

# Interroga il target con SNMPv2c e community 'public' dal container attacker
OUTPUT=$(docker compose exec -T attacker snmpwalk -v2c -c public -t 2 -r 1 target 1.3.6.1.2.1.1.1.0 2>&1)

echo "[*] Risposta ricevuta: $OUTPUT"

if echo "$OUTPUT" | grep -q "Timeout"; then
    echo "[OK] SNMP non risponde alla community predefinita 'public'. Configurazione sicura."
    exit 0
else
    echo "[VULNERABILE] SNMP risponde con community 'public'!"
    exit 1
fi
