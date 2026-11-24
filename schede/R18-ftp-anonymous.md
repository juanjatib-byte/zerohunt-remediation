# R18 - FTP con accesso anonimo abilitato

## Cos'è e perché è un rischio
Consentire l'accesso **anonimo** (`anonymous` / `ftp` senza password o con qualsiasi email) su un server **FTP (porta TCP 21)** espone i file ospitati a qualsiasi utente sulla rete:
- **Esfiltrazione di dati riservati:** configurazioni di rete, backup, sorgenti, documenti interni o credenziali salvate nelle directory condivise possono essere scaricati senza autenticazione.
- **Caricamento di file malevoli (se abilitato anche l'upload anonimo):** un attaccante può usare il server come repository per malware, phishing o saturare lo spazio su disco.
- **Traffico in chiaro:** il protocollo FTP trasmette comandi e file senza cifratura (a differenza di SFTP/FTPS).

## Come verificare il problema
```bash
curl -s --max-time 5 ftp://<IP_TARGET>/
```
*Output atteso PRIMA della correzione (se vulnerabile):* elenco dei file/directory presenti sulla root FTP (es. `-rw-r--r-- 1 0 0 ... segreto.txt`) ottenuto senza fornire credenziali.

## Come rimediare (Remediation)

1. **Disabilitare l'accesso anonimo in `vsftpd` (`/etc/vsftpd.conf`)** impostando `anonymous_enable=NO` e abilitando esclusivamente utenti locali autenticati:
```bash
sed -i 's/^anonymous_enable=.*/anonymous_enable=NO/' /etc/vsftpd.conf
grep -q '^anonymous_enable=' /etc/vsftpd.conf || echo 'anonymous_enable=NO' >> /etc/vsftpd.conf
systemctl restart vsftpd
```
2. **Soluzione consigliata a lungo termine:** dismettere il servizio FTP non cifrato (`systemctl disable --now vsftpd`) e utilizzare esclusivamente **SFTP** (incluso in OpenSSH sulla porta TCP 22).

## Come verificare che sia corretto
```bash
curl -s --max-time 5 ftp://<IP_TARGET>/
```
*Output atteso DOPO la correzione:* errore di autenticazione (`curl: (67) Access denied: 530` / `530 Permission denied`).

## Cosa può rompersi
- Dispositivi di rete legacy (switch/router o stampanti multifunzione) configurati per scaricare firmware o caricare backup/scansioni tramite FTP anonimo smetteranno di funzionare finché non verranno riconfigurati con credenziali dedicate o SFTP.
- Script automatizzati di download pubblico che si connettono senza credenziali riceveranno errore `530 Login incorrect`.

## Fonti
* [vsftpd Official Manpage - vsftpd.conf (anonymous_enable)](https://://appspot.com/vsftpd/vsftpd_conf.html)
* [Ubuntu Server Documentation - FTP Server (vsftpd)](https://ubuntu.com/server/docs/set-up-an-ftp-server)
* [CIS Distribution Independent Linux Benchmark](https://www.cisecurity.org/cis-benchmarks)
