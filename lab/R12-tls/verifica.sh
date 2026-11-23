#!/bin/bash

RUNNING_CONTAINERS=$(docker compose ps --services --filter "status=running" 2>/dev/null)

if [ -z "$RUNNING_CONTAINERS" ]; then
    echo "[ERROR] Nessun container attivo. Esegui prima: docker compose up -d"
    exit 1
fi


echo "[*] Controllo supporto TLS 1.1 su target:443..."

# Tenta una connessione forzando TLS 1.1 dal container attacker
OUTPUT=$(echo "Q" | docker compose exec -T attacker openssl s_client -connect target:443 -tls1_1 -cipher DEFAULT@SECLEVEL=0 2>&1)

# Se l'handshake TLS 1.1 riesce, il server invia il proprio certificato (BEGIN CERTIFICATE)
if echo "$OUTPUT" | grep -q "BEGIN CERTIFICATE"; then
    echo "[VULNERABILE] Il server accetta connessioni con TLS 1.1!"
    exit 1
else
    echo "[OK] TLS 1.1 rifiutato dal server. Configurazione sicura."
    exit 0
fi
