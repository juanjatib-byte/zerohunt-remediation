#!/bin/bash
RUN=$(docker compose ps --services --filter "status=running" 2>/dev/null)
echo "$RUN" | grep -q "^target-" && echo "$RUN" | grep -q "^attacker$" || { echo "[ERROR] Container target o attacker non attivo."; exit 1; }
until docker compose exec -T attacker which nmap >/dev/null 2>&1; do sleep 2; done
echo "[*] Controllo algoritmi SSH deboli su target:22..."
OUT=$(docker compose exec -T attacker nmap -p 22 --script ssh2-enum-algos target 2>&1)
if echo "$OUT" | grep -Eq "diffie-hellman-group1-sha1|aes128-cbc|3des-cbc|hmac-sha1"; then
    echo "[VULNERABILE] Il server SSH accetta algoritmi deboli (CBC / SHA-1 / group1)!" && exit 1
elif echo "$OUT" | grep -q "kex_algorithms"; then
    echo "[OK] Nessun algoritmo SSH debale rilevato. Configurazione sicura." && exit 0
else
    echo "[ERROR] Impossibile interrogare SSH su target: $OUT" && exit 1
fi
