# Lab R02 — SMBv1 attivo

Ambiente Docker per riprodurre e verificare la correzione della vulnerabilità **R02 (SMBv1 attivo)**.

## Struttura
- `Dockerfile`: immagine basata su `debian:bookworm-slim` con `samba` e `smbclient`.
- `docker-compose.yml`: definisce il server Samba (nei profili `vulnerabile` e `corretto`) e il container `attacker` sulla rete interna `lab-net`.
- `vulnerabile/smb.conf`: configurazione con `server min protocol = NT1` (SMBv1 abilitato).
- `corretto/smb.conf`: configurazione sicura con `server min protocol = SMB2` (SMBv1 disabilitato).
- `verifica.sh`: script che tenta una connessione forzata in SMBv1 (`NT1`) dal container `attacker` tramite `smbclient` (esce con `1` se vulnerabile, `0` se corretto).

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
