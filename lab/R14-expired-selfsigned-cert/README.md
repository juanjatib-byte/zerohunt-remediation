# Lab R14 - Certificato scaduto o autofirmato su servizi interni
- `vulnerabile/Dockerfile`: Nginx con certificato autofirmato non emesso da CA aziendale.
- `corretto/Dockerfile`: Nginx con certificato emesso da CA interna (`Corp Internal Root CA`) con SAN `DNS:target`.
- `verifica.sh`: verifica tramite `curl` con trust store aziendale (`exit 1` se vulnerabile/inattivo, `0` se sicuro).
