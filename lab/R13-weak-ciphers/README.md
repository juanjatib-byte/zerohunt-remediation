# Lab R13 - Cifrari deboli (RC4, 3DES, export)

Ambiente Docker per riprodurre e verificare la correzione della vulnerabilità **R13 (Cifrari deboli)**.

## Struttura
- `vulnerabile/Dockerfile`: Nginx configurato con cifrari `3DES:RC4`.
- `corretto/Dockerfile`: Nginx configurato solo con cifrari `ECDHE-RSA-AES*-GCM`.
- `docker-compose.yml`: profili `vulnerabile` e `corretto` + container `attacker`.
- `verifica.sh`: verifica tramite `openssl s_client -cipher '3DES:RC4'` (esce con `1` se vulnerabile/inattivo, `0` se sicuro).

## Istruzioni
1. `docker compose --profile vulnerabile up -d --build` -> `./verifica.sh` (exit 1)
2. `docker compose --profile vulnerabile down && docker compose --profile corretto up -d --build` -> `./verifica.sh` (exit 0)
3. `docker compose --profile vulnerabile --profile corretto down -v --rmi local`
