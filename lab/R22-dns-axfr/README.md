# Lab R22 — DNS: trasferimento di zona (AXFR) permesso

Ambiente Docker per riprodurre e verificare la correzione della vulnerabilità **R22 (Trasferimento di zona DNS AXFR permesso)**.

## Struttura
- `Dockerfile`: immagine basata su `debian:bookworm-slim` con `bind9`, `dnsutils` (`dig`) e la zona di test `zerohunt.local`.
- `docker-compose.yml`: definisce il server DNS BIND9 (nei profili `vulnerabile` e `corretto`) e il container `attacker` sulla rete interna `lab-net`.
- `vulnerabile/named.conf`: configurazione con `allow-transfer { any; };`.
- `corretto/named.conf`: configurazione sicura con `allow-transfer { none; };`.
- `verifica.sh`: script che richiede un trasferimento AXFR dal container `attacker` tramite `dig` (esce con `1` se vulnerabile, `0` se corretto).

## Istruzioni per la prova

### 1. Avviare lo stato vulnerabile
    docker compose --profile vulnerabile up -d --build

### 2. Eseguire la verifica (esito atteso: exit code 1)
    ./verifica.sh
    echo "Exit code: $?"

### 3. Passare allo stato corretto
    docker compose --profile vulnerabile down
    docker compose --profile corretto up -d --build

### 4. Rilanciare la verifica (esito atteso: exit code 0)
    ./verifica.sh
    echo "Exit code: $?"

### 5. Spegnere e ripulire l'ambiente
    docker compose --profile vulnerabile --profile corretto down -v --rmi local
