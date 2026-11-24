# R15 - Interfaccia di gestione in HTTP senza cifratura

## Cos'è e perché è un rischio
Esporre pannelli amministrativi, dashboard di rete o console web su **HTTP in chiaro (porta TCP 80 o porte alternative come 8080)** senza cifratura TLS né reindirizzamento forzato verso HTTPS espone il traffico ad intercettazioni attive e passive:
- **Sniffing delle credenziali e dei token di sessione:** username, password, cookie di sessione e API key viaggiano in chiaro sulla rete e possono essere catturati da qualsiasi host sullo stesso segmento LAN o tramite ARP spoofing.
- **Manipolazione dei comandi (MitM):** un attaccante può alterare in transito le richieste amministrative (es. creazione utenti admin o modifica regole firewall).
- **Assenza di autenticazione del server:** l'amministratore non ha garanzia dell'identità del pannello a cui sta inviando le credenziali.

## Come verificare il problema
```bash
curl -I -s --max-time 5 http://<IP_TARGET>/
```
*Output atteso PRIMA della correzione (se vulnerabile):* `HTTP/1.1 200 OK` (il server risponde direttamente su HTTP in chiaro senza effettuare un redirect `301`/`308` verso `https://`).

## Come rimediare (Remediation)

1. **Abilitare HTTPS (porta TCP 443)** con un certificato TLS valido e **forzare il redirect permanente (HTTP 301)** da HTTP (porta 80) verso HTTPS, aggiungendo l'header **HSTS** ():
   ```nginx
   server {
       listen 80;
       server_name mgmt.azienda.local;
       return 301 https://$host$request_uri;
   }

   server {
       listen 443 ssl;
       server_name mgmt.azienda.local;
       ssl_certificate /etc/ssl/certs/mgmt.crt;
       ssl_certificate_key /etc/ssl/private/mgmt.key;
       add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
       location / {
           proxy_pass http://127.0.0.1:8080;
       }
   }
   ```
2. **Verificare la sintassi e ricaricare Nginx:**
   ```bash
   nginx -t && systemctl reload nginx
   ```
3. **Chiudere la porta HTTP diretta sul firewall** (es. ) in modo che il pannello backend risponda solo su  dietro il reverse proxy HTTPS.

## Come verificare che sia corretto
```bash
curl -I -s --max-time 5 http://<IP_TARGET>/
```
*Output atteso DOPO la correzione:*
```text
HTTP/1.1 301 Moved Permanently
Location: https://<IP_TARGET>/
```

## Cosa può rompersi
- Script di monitoraggio, health-check automatizzati o client API interni configurati con URL hardcoded  che non seguono i redirect ( senza ) o che non si fidano del certificato TLS del pannello potrebbero smettere di funzionare.
- Dispositivi di rete legacy o appliance embedded molto vecchi con browser integrati privi di supporto TLS moderno non potranno più accedere all'interfaccia web.

## Fonti
* [Nginx Documentation - ngx_http_rewrite_module (return 301)](https://nginx.org/en/docs/http/ngx_http_rewrite_module.html#return)
* [Mozilla SSL Configuration Generator (HTTPS & HSTS)](https://ssl-config.mozilla.org/)
* [RFC 6797 - HTTP Strict Transport Security (HSTS)](https://datatracker.ietf.org/doc/html/rfc6797)
