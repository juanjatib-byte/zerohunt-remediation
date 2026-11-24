# R17 - Servizi amministrativi esposti su reti non fidate

## Cos'è e perché è un rischio
Esporre servizi di amministrazione remota o gestione infrastrutturale (es. **SSH 22**, **RDP 3389**, **WinRM 5985/5986**, **console web admin 8080/8443**, **database 3306/5432**) su **tutte le interfacce di rete (`0.0.0.0`)** verso reti non fidate (Internet, reti guest, Wi-Fi dipendenti, VLAN utenti) allarga enormemente la superficie d'attacco:
- **Esposizione a scansioni e attacchi automatizzati:** botnet e attaccanti interni possono tentare brute-force, exploit 0-day o credential stuffing direttamente sui servizi critici.
- **Movimento laterale semplificato:** la compromissione di una singola postazione utente permette di raggiungere immediatamente le porte di gestione dei server e degli apparati di rete.
- **Violazione del principio di segmentazione (Zero Trust):** le interfacce di amministrazione devono essere raggiungibili esclusivamente da una **Management VLAN** dedicata o tramite **VPN / Bastion Host**.

## Come verificare il problema
```bash
ss -tulpn | grep -E ":(22|3389|5985|8080|8443)\b"
```
*Output atteso PRIMA della correzione (se vulnerabile):* `0.0.0.0:8080` o `*:8080` (il servizio è in ascolto su tutte le interfacce di rete anziché su `127.0.0.1` o sull'IP della rete di gestione).

## Come rimediare (Remediation)

1. **Limitare il binding del servizio amministrativo** esclusivamente all'interfaccia locale () o all'IP della **Management VLAN** (es. ) invece di :
   ```nginx
   server {
       listen 127.0.0.1:8080;
       location / {
           proxy_pass http://127.0.0.1:9000;
       }
   }
   ```
2. **Bloccare l'accesso dalle reti non fidate tramite firewall ( / )**, consentendo la porta amministrativa solo dalla subnet di gestione () o dal Bastion Host:
   ```bash
   ufw default deny incoming
   ufw allow from 10.10.99.0/24 to any port 8080 proto tcp
   ufw enable
   ```

## Come verificare che sia corretto
```bash
ss -tulpn | grep :8080
nc -zv -w 3 <IP_TARGET> 8080
```
*Output atteso DOPO la correzione:*  su Netid State  Recv-Q Send-Q Local Address:Port  Peer Address:PortProcess
udp   UNCONN 0      0            0.0.0.0:55311      0.0.0.0:*          
udp   UNCONN 0      0      127.0.0.53%lo:53         0.0.0.0:*          
udp   UNCONN 0      0            0.0.0.0:5353       0.0.0.0:*          
udp   UNCONN 0      0               [::]:5353          [::]:*          
udp   UNCONN 0      0               [::]:39171         [::]:*          
tcp   LISTEN 0      128        127.0.0.1:631        0.0.0.0:*          
tcp   LISTEN 0      4096   127.0.0.53%lo:53         0.0.0.0:*          
tcp   LISTEN 0      128            [::1]:631           [::]:*          , e  /  dai client fuori dalla rete di gestione.

## Cosa può rompersi
- Gli amministratori che tentano di collegarsi direttamente dall'ufficio, dalla rete Wi-Fi utenti o da reti esterne senza passare prima dalla **VPN aziendale** o dal **Bastion Host / Jump Server** perderanno l'accesso alle console di gestione.
- Strumenti di monitoraggio (Zabbix, Prometheus, Nagios) collocati in un'altra subnet dovranno essere aggiunti esplicitamente nelle regole  del firewall.

## Fonti
* [NIST SP 800-41 Rev. 1 - Guidelines on Firewalls and Firewall Policy](https://csrc.nist.gov/pubs/sp/800/41/r1/final)
* [Ubuntu Server Documentation - Firewalls (UFW)](https://ubuntu.com/server/docs/firewalls)
* [Nginx Documentation - ngx_http_core_module (listen directive)](https://nginx.org/en/docs/http/ngx_http_core_module.html#listen)
