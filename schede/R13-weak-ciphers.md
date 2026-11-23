# R13 - Cifrari deboli (RC4, 3DES, export)

## Cos'è e perché è un rischio
Quando un server TLS/HTTPS (porta TCP 443 o altri servizi cifrati) consente la negoziazione di **cipher suite obsolete o deboli** come **RC4**, **3DES** o cifrari **EXPORT** (a 40/56 bit), la riservatezza delle comunicazioni può essere compromessa anche se viene utilizzato TLS 1.2:
- **RC4:** cifrario a flusso con gravi bias statistici (es. attacchi *Bar-Mitzvah* e *NOMORE*), deprecato ufficialmente dalla RFC 7465.
- **3DES (Triple DES):** utilizza blocchi da 64 bit, rendendolo vulnerabile ad attacchi di collisione sul birthday bound (*Sweet32*, CVE-2016-2183) dopo circa 32 GB di dati trasferiti.
- **Cifrari EXPORT / NULL / DES:** offrono una lunghezza di chiave ridotta (40/56 bit) o nessuna cifratura, consentendo la decifratura del traffico in tempo reale o tramite attacchi downgrade (*FREAK* / *Logjam*).

## Come verificare il problema

### Dalla rete (Nmap / OpenSSL)
Utilizzare `nmap` con lo script `ssl-enum-ciphers` per elencare tutti i cifrari accettati dal server:
```bash
nmap -p 443 --script ssl-enum-ciphers <IP_TARGET>
```
Oppure testare esplicitamente un cifrario debole con `openssl`:
```bash
openssl s_client -connect <IP_TARGET>:443 -cipher '3DES:RC4:EXP'
```
*Output atteso PRIMA della correzione (se vulnerabile):*
```text
Cipher    : ECDHE-RSA-DES-CBC3-SHA
```
*(La connessione viene stabilita utilizzando un cifrario 3DES o RC4).*

## Come rimediare (Remediation)

### Nginx (`/etc/nginx/conf.d/ssl.conf` o blocco `server`)
Configurare esclusivamente cipher suite moderne con *Forward Secrecy* (ECDHE) e cifratura autenticata (AEAD: AES-GCM e ChaCha20-Poly1305):
```nginx
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305';
ssl_prefer_server_ciphers on;
```
Verificare e ricaricare Nginx:
```bash
nginx -t && systemctl reload nginx
```

### Apache HTTP Server (`/etc/apache2/mods-available/ssl.conf`)
```apache
SSLProtocol all -SSLv3 -TLSv1 -TLSv1.1
SSLCipherSuite ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384
SSLHonorCipherOrder on
```

## Come verificare che sia corretto
```bash
openssl s_client -connect <IP_TARGET>:443 -cipher '3DES:RC4:EXP'
```
*Output atteso DOPO la correzione:* `ssl/tls alert handshake failure`

## Cosa può rompersi
Client estremamente datati (es. Windows XP/Vista, vecchi dispositivi embedded o Java 6/7) che non supportano cifrari AEAD (`GCM` / `ChaCha20`).

## Fonti
* [Mozilla SSL Configuration Generator](https://ssl-config.mozilla.org/)
* [RFC 7465 - Prohibiting RC4 Cipher Suites](https://datatracker.ietf.org/doc/html/rfc7465)
* [CVE-2016-2183 - Sweet32](https://sweet32.info)
