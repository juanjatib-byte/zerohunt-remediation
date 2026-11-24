#!/bin/bash
RUN=$(docker compose ps --services --filter "status=running" 2>/dev/null)
echo "$RUN" | grep -q "^target-" && echo "$RUN" | grep -q "^attacker$" || { echo "[ERROR] Container target o attacker non attivo."; exit 1; }
echo "[*] Controllo trasferimento di zona DNS (AXFR) su target per zerohunt.local..."
OUT=$(docker compose exec -T attacker dig @target zerohunt.local AXFR +noall +answer 2>&1)
OUT_FULL=$(docker compose exec -T attacker dig @target zerohunt.local AXFR 2>&1)
if echo "$OUT" | grep -q "IN[[:space:]]*SOA"; then
    echo "[VULNERABILE] Trasferimento di zona AXFR permesso!" && exit 1
elif echo "$OUT_FULL" | grep -Eqi "Transfer failed|REFUSED|NOTAUTH"; then
    echo "[OK] Trasferimento di zona AXFR rifiutato. Configurazione sicura." && exit 0
else
    echo "[ERROR] Server DNS non raggiungibile o errore: $OUT_FULL" && exit 1
fi
