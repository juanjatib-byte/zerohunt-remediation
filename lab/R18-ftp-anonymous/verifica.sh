#!/bin/bash
[ -z "$(docker compose ps --services --filter 'status=running' 2>/dev/null)" ] && echo "[ERROR] Nessun container attivo." && exit 1
until docker compose exec -T attacker which curl >/dev/null 2>&1; do sleep 2; done
echo "[*] Controllo accesso FTP anonimo su ftp://target/..."
OUT=$(docker compose exec -T attacker curl -sS --max-time 5 ftp://target/ 2>&1)
if echo "$OUT" | grep -q "segreto.txt"; then
    echo "[VULNERABILE] Accesso FTP anonimo abilitato (file listato: segreto.txt)!" && exit 1
elif echo "$OUT" | grep -Eq "Access denied: 530|530 Permission denied|530 Login incorrect"; then
    echo "[OK] Accesso FTP anonimo rifiutato (530). Configurazione sicura." && exit 0
else
    echo "[ERROR] Risposta inattesa: $OUT" && exit 1
fi
