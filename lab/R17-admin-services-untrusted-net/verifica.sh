#!/bin/bash
RUN=$(docker compose ps --services --filter "status=running" 2>/dev/null)
echo "$RUN" | grep -q "^target-" && echo "$RUN" | grep -q "^attacker$" || { echo "[ERROR] Container target o attacker non attivo."; exit 1; }
until docker compose exec -T attacker which nc >/dev/null 2>&1; do sleep 2; done
echo "[*] Controllo esposizione porta amministrativa 8080 verso rete non fidata..."
OUT=$(docker compose exec -T attacker nc -zv -w 3 target 8080 2>&1)
if echo "$OUT" | grep -Eqi "open|succeeded"; then
    echo "[VULNERABILE] Console amministrativa (8080) raggiunta da rete non fidata!" && exit 1
elif echo "$OUT" | grep -qi "Connection refused|failed|No route to host"; then
    echo "[OK] Porta 8080 non raggiungibile da reti non fidate (binding locale). Sicuro." && exit 0
else
    echo "[ERROR] Target non raggiungibile o errore di rete: $OUT" && exit 1
fi
