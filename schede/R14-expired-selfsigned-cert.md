# R14 - Certificato scaduto o autofirmato su servizi interni

## Cos'è e perché è un rischio
L'utilizzo di certificati **scaduti** o **autofirmati (self-signed)** non emessi da una Certification Authority (CA) attendibile su interfacce amministrative e servizi interni HTTPS/TLS (porta TCP 443 o simili) compromette l'autenticazione del server:
- **Attacchi Man-in-the-Middle (MitM):** senza una catena di fiducia valida, un attaccante nella rete interna può intercettare il traffico presentando un proprio certificato falso senza che l'utente o il client possano distinguerlo da quello legittimo.
- **Abitudine al bypass degli avvisi (Alert Fatigue):** gli amministratori si abituano a cliccare su *"Accetta il rischio e continua"* nel browser, rendendo inefficace qualsiasi protezione TLS.
- **Interruzione improvvisa dei servizi:** un certificato scaduto blocca connessioni automatizzate (API, webhook, script) o esclude dal controllo di revoca (CRL/OCSP).

## Come verificare il problema

### Dalla rete (OpenSSL)
```bash
echo | openssl s_client -connect <IP_TARGET>:443 -servername <HOST_TARGET> 2>/dev/null | openssl x509 -noout -issuer -subject -dates
```
*Output atteso PRIMA della correzione (se autofirmato o scaduto):*
```text
issuer=CN = target
subject=CN = target
notBefore=Jan  1 00:00:00 2020 GMT
notAfter=Jan  1 00:00:00 2021 GMT
```
*(Se `issuer` coincide con `subject` il certificato è autofirmato; se `notAfter` è anteriore alla data odierna il certificato è scaduto).*

## Come rimediare (Remediation)

1. **Sostituire i certificati autofirmati o scaduti** con certificati emessi da una **PKI aziendale interna** (es. Active Directory Certificate Services, Step-CA, Vault PKI) oppure da una CA pubblica (es. Let's Encrypt con DNS-01 challenge per domini interni).
2. **Distribuire il certificato Root CA aziendale** nei trust store dei client (`update-ca-certificates` su Linux o GPO su Windows) e configurare il web server (es. Nginx):
   ```bash
   cp fullchain.pem /etc/ssl/certs/servizio-interno.crt
   cp privkey.pem /etc/ssl/private/servizio-interno.key
   chmod 600 /etc/ssl/private/servizio-interno.key
   nginx -t && systemctl reload nginx
   ```
3. **Automatizzare il rinnovo** prima della scadenza (es. ACME/Certbot o auto-enrollment PKI) con monitoraggio della data `notAfter`.

## Come verificare che sia corretto
```bash
curl -Iv --cacert /etc/ssl/certs/corp-root-ca.crt https://<HOST_TARGET>/
```
*Output atteso DOPO la correzione:* `SSL certificate verify ok.` e stato HTTP `200 OK`.

## Cosa può rompersi
- Client, script, container o dispositivi IoT/stampanti interni che **non hanno ancora installato la Root CA aziendale** nel proprio trust store rifiuteranno la connessione TLS (`SSL certificate problem: unable to get local issuer certificate`).
- Applicazioni che usano *certificate pinning* hardcoded dovranno essere aggiornate con il nuovo certificato o la nuova CA.

## Fonti
* [Mozilla SSL Configuration Generator](https://ssl-config.mozilla.org/)
* [RFC 5280 - Internet X.509 Public Key Infrastructure Certificate and CRL Profile](https://datatracker.ietf.org/doc/html/rfc5280)
* [Nginx Documentation - Configuring HTTPS servers](https://nginx.org/en/docs/http/configuring_https_servers.html)
