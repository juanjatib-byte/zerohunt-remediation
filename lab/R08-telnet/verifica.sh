#!/bin/bash
RUN=$(docker compose ps --services --filter "status=running" 2>/dev/null)
echo "$RUN" | grep -q "^target-" && echo "$RUN" | grep -q "^attacker$" || { echo "[ERROR] Container target o attacker non attivo."; exit 1; }
echo "[*] Controllo esposizione Telnet (porta 23) su target..."
OUT=$(docker compose exec -T attacker nc -zv -w 2 target 23 2>&1)
if echo "$OUT" | grep -Eqi "open|succeeded"; then
    echo "[VULNERABILE] Il servizio Telnet (porta 23) è attivo e raggiungibile!" && exit 1
elif echo "$OUT" | grep -qi "Connection refused"; then
    echo "[OK] Porta 23 chiusa (Telnet disabilitato). Configurazione sicura." && exit 0
else
    echo "[ERROR] Target non raggiungibile o errore di rete: $OUT" && exit 1
fi
