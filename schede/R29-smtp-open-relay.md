# R29 - SMTP open relay

## Cos'è e perché è un rischio
Un server **SMTP (porta TCP 25)** configurato come **Open Relay** accetta e inoltra messaggi di posta elettronica provenienti da qualsiasi indirizzo IP esterno verso domini di destinazione esterni senza richiedere autenticazione:
- **Invio massivo di spam e phishing:** gli attaccanti sfruttano il server per inviare campagne di phishing e malware utilizzando l'IP e il dominio legittimo dell'organizzazione.
- **Blacklisting immediato (RBL / DNSBL):** l'indirizzo IP pubblico del mail server viene inserito rapidamente nelle blacklist internazionali (Spamhaus, Barracuda), bloccando tutte le email aziendali legittime verso l'esterno.
- **Abuso delle risorse:** la coda di posta si satura rapidamente degradando le prestazioni del server.

## Come verificare il problema
```bash
nmap -p 25 --script smtp-open-relay <IP_TARGET>
```
*Output atteso PRIMA della correzione (se vulnerabile):* `smtp-open-relay: Server is an open relay` (il server accetta `MAIL FROM:<esterno@test.com>` e `RCPT TO:<vittima@esterno.org>` senza autenticazione).

## Come rimediare (Remediation)

1. **In Postfix (`/etc/postfix/main.cf`):** limitare `mynetworks` esclusivamente a `127.0.0.0/8` e impostare `smtpd_relay_restrictions` in modo da consentire l'inoltro solo agli utenti autenticati (SASL) e alle reti fidate:
```bash
postconf -e "mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128"
postconf -e "smtpd_relay_restrictions = permit_mynetworks, permit_sasl_authenticated, reject_unauth_destination"
systemctl reload postfix
```
2. **In Microsoft Exchange Server:** verificare i *Receive Connectors* su porta `25` e rimuovere l'autorizzazione **Anonymous users** dai connettori che hanno il permesso `ms-Exch-SMTP-Accept-Any-Recipient`.

## Come verificare che sia corretto
```bash
nmap -p 25 --script smtp-open-relay <IP_TARGET>
```
*Output atteso DOPO la correzione:* `Server doesn't seem to be an open relay` (`554 5.7.1 Relay access denied`).

## Cosa può rompersi
- Stampanti multifunzione, scanner, sistemi ERP o server applicativi interni configurati per inviare email tramite questo server SMTP **senza autenticazione** da subnet non incluse in `mynetworks` riceveranno `554 5.7.1 Relay access denied` finché non verranno configurati con **SMTP AUTH (porta 587 STARTTLS)** o aggiunti esplicitamente in una relay ACL dedicata.

## Fonti
* [Postfix Documentation - SMTP Relay and Access Control](https://www.postfix.org/SMTP_RELAY_README.html)
* [Microsoft Learn - Exchange Server Receive Connectors and Relay Permissions](https://learn.microsoft.com/en-us/exchange/mail-flow/connectors/receive-connectors?view=exchdocs-2019)
