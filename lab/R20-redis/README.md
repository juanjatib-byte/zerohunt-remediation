# Lab R20 — Redis esposto senza autenticazione

Ambiente Docker per riprodurre e verificare la correzione della vulnerabilità **R20 (Redis senza autenticazione)**.

## Struttura
- `docker-compose.yml`: definisce il target Redis (nei due profili `vulnerabile` e `corretto`) e il container `attacker` sulla rete interna `lab-net`.
- `vulnerabile/redis.conf`: configurazione predefinita senza password.
- `corretto/redis.conf`: configurazione corretta con direttiva `requirepass`.
- `verifica.sh`: script che interroga Redis dal container `attacker` (esce con `1` se vulnerabile, `0` se corretto).

## Istruzioni per la prova

### 1. Avviare lo stato vulnerabile
```bash
docker compose --profile vulnerabile up -d
```

### 2. Eseguire la verifica (esito atteso: exit code 1)
```bash
./verifica.sh
echo "Exit code: \$?"
```

### 3. Passare allo stato corretto
```bash
docker compose --profile vulnerabile down
docker compose --profile corretto up -d
```

### 4. Rilanciare la verifica (esito atteso: exit code 0)
```bash
./verifica.sh
echo "Exit code: \$?"
```

### 5. Spegnere e ripulire l'ambiente
```bash
docker compose --profile vulnerabile --profile corretto down -v
```
