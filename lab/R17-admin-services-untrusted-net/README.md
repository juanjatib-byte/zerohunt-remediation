# Lab R17 - Servizi amministrativi esposti su reti non fidate
- `vulnerabile/Dockerfile`: Nginx espone la console di gestione su `0.0.0.0:8080`.
- `corretto/Dockerfile`: Nginx limita l'ascolto a `127.0.0.1:8080` (raggiungibile solo localmente / Bastion Host).
- `verifica.sh`: verifica tramite `nc -zv target 8080` da `attacker` (`exit 1` se esposto/inattivo, `0` se bloccato).
