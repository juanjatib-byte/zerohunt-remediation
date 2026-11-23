# Lab R10 - SSH con login root e password abilitati

Ambiente Docker per riprodurre e verificare la correzione della vulnerabilità **R10 (SSH con login root e password abilitati)**.

## Struttura

- `vulnerabile/Dockerfile`: immagine basata su `debian:bookworm-slim` con `openssh-server` configurato con `PermitRootLogin yes` e `PasswordAuthentication yes`.
- `corretto/Dockerfile`: immagine basata su `debian:bookworm-slim` con `openssh-server` configurato con `PermitRootLogin no`, `PasswordAuthentication no` e `PubkeyAuthentication yes`.
- `docker-compose.yml`: definisce i target (nei profili `vulnerabile` e `corretto`) e il container `attacker` sulla rete interna `lab_net`.
- `verifica.sh`: script che verifica dal container `attacker` se il server accetta autenticazione via password per `root` (esce con `1` se vulnerabile o se nessun container è attivo, `0` se corretto).

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
