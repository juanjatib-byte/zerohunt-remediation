#!/bin/bash
[ -z "$(docker compose ps --services --filter 'status=running' 2>/dev/null)" ] && echo "[ERROR] Nessun container attivo." && exit 1
until docker compose exec -T attacker which curl >/dev/null 2>&1; do sleep 2; done
echo "[*] Controllo interfaccia HTTP su http://target/..."
OUT=$(docker compose exec -T attacker curl -I -s --max-time 5 http://target/ 2>&1)
if echo "$OUT" | grep -q "HTTP/1.1 200 OK"; then
    echo "[VULNERABILE] L'interfaccia risponde in chiaro su HTTP (200 OK) senza redirect HTTPS!" && exit 1
elif echo "$OUT" | grep -Eq "HTTP/1.1 301|HTTP/1.1 308" && echo "$OUT" | grep -qi "Location: https://"; then
    echo "[OK] Redirect obbligatorio verso HTTPS attivo. Configurazione sicura." && exit 0
else
    echo "[ERROR] Risposta inattesa: $OUT" && exit 1
fi
