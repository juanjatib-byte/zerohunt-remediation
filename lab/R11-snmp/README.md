# Lab R11 — SNMP v1/v2c con community predefinite (public, private)

Ambiente Docker per riprodurre e verificare la correzione della vulnerabilità **R11 (SNMP con community predefinite)**.

## Struttura
- `Dockerfile`: immagine basata su `debian:bookworm-slim` con `snmpd` e `snmp`.
- `docker-compose.yml`: definisce il target SNMP (nei profili `vulnerabile` e `corretto`) e il container `attacker` sulla rete interna `lab-net`.
- `vulnerabile/snmpd.conf`: configurazione con community predefinita `public` abilitata.
- `corretto/snmpd.conf`: configurazione sicura con solo SNMPv3 autenticato e cifrato (`SHA` + `AES`).
- `verifica.sh`: script che interroga il target dal container `attacker` con `snmpwalk` (esce con `1` se vulnerabile, `0` se corretto).

## Istruzioni per la prova

### 1. Avviare lo stato vulnerabile
```bash
docker compose --profile vulnerabile up -d --build
```

### 2. Eseguire la verifica (esito atteso: exit code 1)
```bash
./verifica.sh
echo "Exit code: \$?"
```

### 3. Passare allo stato corretto
```bash
docker compose --profile vulnerabile down
docker compose --profile corretto up -d --build
```

### 4. Rilanciare la verifica (esito atteso: exit code 0)
```bash
./verifica.sh
echo "Exit code: \$?"
```

### 5. Spegnere e ripulire l'ambiente
```bash
docker compose --profile vulnerabile --profile corretto down -v --rmi local
```
