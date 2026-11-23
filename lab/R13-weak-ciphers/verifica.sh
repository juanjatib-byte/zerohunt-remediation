#!/bin/bash
[ -z "$(docker compose ps --services --filter 'status=running' 2>/dev/null)" ] && echo "[ERROR] Nessun container attivo." && exit 1
until docker compose exec -T attacker which nmap >/dev/null 2>&1; do sleep 2; done
echo "[*] Controllo cifrari deboli (3DES/CBC/RSA-static) su target:443..."
OUT=$(docker compose exec -T attacker nmap -p 443 --script ssl-enum-ciphers target 2>&1)
if echo "$OUT" | grep -Eq "3DES|DES-CBC3|TLS_RSA_WITH_"; then
    echo "[VULNERABILE] Il server accetta cifrari deboli!" && exit 1
elif echo "$OUT" | grep -q "TLS_ECDHE_RSA_WITH_AES"; then
    echo "[OK] Solo cifrari AEAD moderni (ECDHE+GCM) attivi. Configurazione sicura." && exit 0
else
    echo "[ERROR] Risposta inattesa: $OUT" && exit 1
fi
