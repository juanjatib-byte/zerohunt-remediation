# Lab R09 - SSH con algoritmi deboli

Ambiente Docker per riprodurre e verificare la correzione della vulnerabilità **R09 (SSH con algoritmi deboli: CBC, SHA-1, diffie-hellman-group1)**.

## Struttura

- `vulnerabile/Dockerfile`: immagine basata su `debian:bookworm-slim` con `openssh-server` configurato con algoritmi obsoleti (`diffie-hellman-group1-sha1`, `aes128-cbc`, `3des-cbc`, `hmac-sha1`).
- `corretto/Dockerfile`: immagine basata su `debian:bookworm-slim` con `openssh-server` configurato esclusivamente con algoritmi moderni (`curve25519-sha256`, `chacha20-poly1305`, `aes256-gcm`, `hmac-sha2-512-etm`).
- `docker-compose.yml`: definisce i target (nei profili `vulnerabile` e `corretto`) e il container `attacker` sulla rete interna `lab_net`.
- `verifica.sh`: script che verifica dal container `attacker` tramite `nmap --script ssh2-enum-algos` se il server espone algoritmi deboli (esce con `1` se vulnerabile o se nessun container è attivo, `0` se corretto).

## Istruzioni per la prova

### 1. Avviare lo stato vulnerabile
```bash
docker compose --profile vulnerabile up -d --build
```

### 2. Eseguire la verifica (esito atteso: exit code 1)
```bash
./verifica.sh
echo "Exit code: $?"
```

### 3. Passare allo stato corretto
```bash
docker compose --profile vulnerabile down
docker compose --profile corretto up -d --build
```

### 4. Rilanciare la verifica (esito atteso: exit code 0)
```bash
./verifica.sh
echo "Exit code: $?"
```

### 5. Spegnere e ripulire l'ambiente
```bash
docker compose --profile vulnerabile --profile corretto down -v --rmi local
```
