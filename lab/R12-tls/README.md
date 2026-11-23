# Lab R12 — TLS 1.0 / 1.1 abilitati

Ambiente Docker per riprodurre e verificare la correzione della vulnerabilità **R12 (TLS 1.0 / 1.1 abilitati)**.

## Struttura
- `Dockerfile`: immagine basata su `debian:bookworm-slim` con `nginx`, `openssl` e certificato autofirmato generato al build.
- `docker-compose.yml`: definisce il server HTTPS Nginx (nei profili `vulnerabile` e `corretto`) e il container `attacker` sulla rete interna `lab-net`.
- `vulnerabile/nginx.conf`: configurazione che accetta connessioni `TLSv1` e `TLSv1.1`.
- `corretto/nginx.conf`: configurazione sicura con `ssl_protocols TLSv1.2 TLSv1.3;`.
- `verifica.sh`: script che tenta una connessione TLS 1.1 dal container `attacker` tramite `openssl s_client` (esce con `1` se vulnerabile, `0` se corretto).

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
