# Lab R15 - Interfaccia di gestione in HTTP senza cifratura
- `vulnerabile/Dockerfile`: Nginx espone il pannello su HTTP porta 80 (`200 OK`) senza HTTPS.
- `corretto/Dockerfile`: Nginx esegue redirect `301` da HTTP (80) verso HTTPS (443) con header HSTS.
- `verifica.sh`: verifica tramite `curl -I http://target/` (`exit 1` se vulnerabile/inattivo, `0` se sicuro).
