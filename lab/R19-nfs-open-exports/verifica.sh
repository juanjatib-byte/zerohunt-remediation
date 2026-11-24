#!/bin/bash
[ -z "$(docker compose ps --services --filter 'status=running' 2>/dev/null)" ] && echo "[ERROR] Nessun container attivo." && exit 1
until docker compose exec -T attacker which showmount >/dev/null 2>&1; do sleep 2; done
echo "[*] Controllo export NFS tramite showmount -e target..."
OUT=$(docker compose exec -T attacker showmount -e target 2>&1)
if echo "$OUT" | grep -Eq "/srv/nfs[[:space:]]+\*|everyone|0\.0\.0\.0/0"; then
    echo "[VULNERABILE] Export NFS aperto a tutti (*): $OUT" && exit 1
elif echo "$OUT" | grep -q "/srv/nfs 10.250.250.0/24"; then
    echo "[OK] Export NFS limitato alla subnet autorizzata. Configurazione sicura." && exit 0
else
    echo "[ERROR] Risposta inattesa: $OUT" && exit 1
fi
