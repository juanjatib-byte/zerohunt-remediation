#!/bin/bash
RUN=$(docker compose ps --services --filter "status=running" 2>/dev/null)
echo "$RUN" | grep -q "^target-" && echo "$RUN" | grep -q "^attacker$" || { echo "[ERROR] Container target o attacker non attivo."; exit 1; }
until docker compose exec -T attacker which nc >/dev/null 2>&1; do sleep 2; done
echo "[*] Controllo esposizione porta amministrativa 8080 verso rete non fidata..."
docker compose exec -T attacker ping -c 1 -W 1 target >/dev/null 2>&1 || { echo "[ERROR] Target non raggiungibile in rete."; exit 1; }
if docker compose exec -T attacker nc -zv -w 3 target 8080 >/dev/null 2>&1; then
    echo "[VULNERABILE] Console amministrativa (8080) raggiunta da rete non fidata!" && exit 1
else
    echo "[OK] Porta 8080 non raggiungibile da reti non fidate (binding locale). Sicuro." && exit 0
fi
