#!/bin/bash
RUN=$(docker compose ps --services --filter "status=running" 2>/dev/null)
echo "$RUN" | grep -q "^target-" && echo "$RUN" | grep -q "^attacker$" || { echo "[ERROR] Container target o attacker non attivo."; exit 1; }
echo "[*] Controllo supporto SMBv1 (NT1) su target:445..."
OUT=$(docker compose exec -T attacker smbclient -L //target -N --option="client min protocol=NT1" --option="client max protocol=NT1" 2>&1)
if echo "$OUT" | grep -q "Sharename"; then
    echo "[VULNERABILE] Il server accetta connessioni con SMBv1 (NT1)!" && exit 1
elif echo "$OUT" | grep -Eqi "protocol negotiation failed|NT_STATUS_CONNECTION_RESET|NT_STATUS_INVALID_NETWORK_RESPONSE"; then
    echo "[OK] SMBv1 (NT1) rifiutato dal server. Configurazione sicura." && exit 0
else
    echo "[ERROR] Risposta inattesa dal target: $OUT" && exit 1
fi
