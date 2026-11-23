#!/bin/bash
[ -z "$(docker compose ps --services --filter 'status=running' 2>/dev/null)" ] && echo "[ERROR] Nessun container attivo." && exit 1
until docker compose exec -T attacker which curl >/dev/null 2>&1; do sleep 2; done
echo "[*] Verifica validità certificato HTTPS su https://target/..."
OUT=$(docker compose exec -T attacker curl -sS --max-time 5 https://target/ 2>&1)
if [ "$OUT" = "OK" ]; then
    echo "[OK] Certificato valido e firmato da CA attendibile. Configurazione sicura." && exit 0
elif echo "$OUT" | grep -Eq "SSL certificate|self-signed|unable to get local issuer|certificate verify failed"; then
    echo "[VULNERABILE] Certificato non attendibile o autofirmato: $OUT" && exit 1
else
    echo "[ERROR] Risposta inattesa: $OUT" && exit 1
fi
