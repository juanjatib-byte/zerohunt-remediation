# Lab R16 - Credenziali di default su pannelli e dispositivi
- `vulnerabile/Dockerfile`: Nginx con Basic Auth configurato con `admin:admin`.
- `corretto/Dockerfile`: Nginx con Basic Auth configurato con utente nominativo e password robusta (`htpasswd -B`).
- `verifica.sh`: verifica tramite `curl -u admin:admin http://target/admin/` (`exit 1` se vulnerabile/inattivo, `0` se sicuro).
