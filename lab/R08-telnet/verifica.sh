#!/bin/bash

echo "[*] Controllo porta Telnet (TCP 23) su target..."

# Verifica dall'attacker se la porta 23 di target accetta connessioni
if docker compose exec -T attacker nc -zv -w 2 target 23 >/dev/null 2>&1; then
    echo "[VULNERABILE] Il servizio Telnet (porta 23) è attivo e raggiungibile!"
    exit 1
else
    echo "[OK] Porta 23 chiusa (Telnet disabilitato). Configurazione sicura."
    exit 0
fi
