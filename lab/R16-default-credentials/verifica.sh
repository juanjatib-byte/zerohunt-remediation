#!/bin/bash
[ -z "$(docker compose ps --services --filter 'status=running' 2>/dev/null)" ] && echo "[ERROR] Nessun container attivo." && exit 1
until docker compose exec -T attacker which curl >/dev/null 2>&1; do sleep 2; done
echo "[*] Verifica credenziali di default (admin:admin) su http://target/admin/..."
CODE=$(docker compose exec -T attacker curl -s -o /dev/null -w "%{http_code}" --max-time 5 -u admin:admin http://target/admin/ 2>&1)
if [ "$CODE" = "200" ]; then
    echo "[VULNERABILE] Accesso consentito con credenziali di default admin:admin (HTTP 200)!" && exit 1
elif [ "$CODE" = "401" ]; then
    echo "[OK] Credenziali di default rifiutate (HTTP 401). Configurazione sicura." && exit 0
else
    echo "[ERROR] Risposta inattesa (HTTP $CODE)." && exit 1
fi
