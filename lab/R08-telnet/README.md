# Lab R08 — Telnet attivo

Ambiente Docker per riprodurre e verificare la correzione della vulnerabilità **R08 (Telnet attivo)**.

## Struttura
- `Dockerfile`: immagine basata su `debian:bookworm-slim` con `inetutils-inetd`, `inetutils-telnetd`, `openssh-server` e `netcat-openbsd`.
- `docker-compose.yml`: definisce il target (nei profili `vulnerabile` e `corretto`) e il container `attacker` sulla rete interna `lab-net`.
- `vulnerabile/inetd.conf`: configurazione con servizio Telnet abilitato sulla porta TCP 23.
- `corretto/inetd.conf`: configurazione sicura con servizio Telnet disabilitato e solo SSH attivo.
- `verifica.sh`: script che verifica dal container `attacker` se la porta TCP 23 è aperta (esce con `1` se vulnerabile, `0` se corretto).

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
