#!/bin/bash
RUN=$(docker compose ps --services --filter "status=running" 2>/dev/null)
echo "$RUN" | grep -q "^target-" && echo "$RUN" | grep -q "^attacker$" || { echo "[ERROR] Container target o attacker non attivo."; exit 1; }
echo "[*] Controllo supporto TLS 1.1 su target:443..."
OUT=$(echo "Q" | docker compose exec -T attacker openssl s_client -connect target:443 -tls1_1 -cipher DEFAULT@SECLEVEL=0 2>&1)
if echo "$OUT" | grep -q "BEGIN CERTIFICATE"; then
    echo "[VULNERABILE] Il server accetta connessioni con TLS 1.1!" && exit 1
elif echo "$OUT" | grep -Eqi "alert protocol version|no protocols available|wrong version number|handshake failure"; then
    echo "[OK] TLS 1.1 rifiutato dal server. Configurazione sicura." && exit 0
else
    echo "[ERROR] Target non raggiungibile o errore TLS: $OUT" && exit 1
fi
