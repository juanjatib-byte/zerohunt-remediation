# R25 - IPMI esposto (cipher 0, hash recuperabili)

## Cos'è e perché è un rischio
L'interfaccia **IPMI 2.0 (Intelligent Platform Management Interface, porta UDP 623)** presente nei controller BMC (iDRAC, iLO, Supermicro IPMI) presenta gravi difetti crittografici nel protocollo RMCP+ se lasciata esposta su reti non isolate:
- **Authentication Bypass con Cipher Suite 0:** specificando `cipher 0` nella negoziazione RMCP+, il BMC consente l'autenticazione amministrativa con qualsiasi password senza verificare le credenziali.
- **Recupero offline degli hash (RAKP HMAC-SHA1):** durante il 2° messaggio dell'handshake RAKP (`Get User Access` / session setup), il BMC invia l'hash HMAC-SHA1 della password di qualsiasi utente valido (es. `ADMIN`) prima che il client dimostri di conoscere la password, consentendo cracking offline istantaneo.
- **Controllo totale a livello hardware (Out-of-Band):** un attaccante ottiene console KVM remota, montaggio di ISO virtuali, accensione/spegnimento del server e accesso al BIOS/firmware indipendentemente dal sistema operativo.

## Come verificare il problema
```bash
ipmitool -I lanplus -C 0 -H <IP_BMC> -U admin -P qualsiasi chassis status
nmap -sU -p 623 --script ipmi-version,ipmi-cipher-zero <IP_BMC>
```
*Output atteso PRIMA della correzione (se vulnerabile):* `System Power : on` con `-C 0` (Cipher 0 accettato) oppure `ipmi-cipher-zero: VULNERABLE`.

## Come rimediare (Remediation)

1. **Segregare immediatamente le interfacce BMC / IPMI** su una **Management VLAN Out-of-Band (OOB)** dedicata, priva di accesso da Internet e dalle reti utenti/server, accessibile solo tramite VPN amministrativa o Bastion Host.
2. **Disabilitare Cipher Suite 0** e consentire esclusivamente Cipher Suite sicure (es. Cipher Suite `3` o `17` con SHA-256) tramite `ipmitool`:
```bash
ipmitool -I lanplus -H <IP_BMC> -U admin -P <PASSWORD> lan set 1 cipher_privs XXXXXXXXXXXXXXX
ipmitool -I lanplus -H <IP_BMC> -U admin -P <PASSWORD> lan set 1 cipher_privs caaaaaaaaaaaaaa
```
*(Il primo carattere `X` disabilita il Cipher 0; l'impostazione varia in base al numero di suite supportate dal firmware del vendor).*
3. **Aggiornare il firmware BMC (iDRAC/iLO/IPMI)** all'ultima versione disponibile, cambiare la password dell'utente `ADMIN` con una stringa casuale > 20 caratteri e disabilitare IPMI over LAN se si usa solo l'interfaccia web HTTPS del BMC.

## Come verificare che sia corretto
```bash
ipmitool -I lanplus -C 0 -H <IP_BMC> -U admin -P qualsiasi chassis status
```
*Output atteso DOPO la correzione:* `Error: Unable to establish IPMI v2 / RMCP+ session` (connessione rifiutata dalla rete non fidata o Cipher 0 negato).

## Cosa può rompersi
- Sistemi di inventario hardware, orchestrazione bare-metal (MAAS, Foreman, Ansible) o monitoraggio termico/energetico che interrogano i BMC da una VLAN diversa dalla rete OOB perderanno connettività finché non verranno instradati attraverso il Bastion Host / ACL dedicata.
- Vecchi script di automazione che usano `ipmitool` con cipher suite legacy o senza `-C 3` / `-C 17` non riusciranno più ad aprire sessioni RMCP+.

## Fonti
* [CISA Alert TA13-207A - Risks of Using Intelligent Platform Management Interface (IPMI)](https://www.cisa.gov/news-events/alerts/2013/07/26/risks-using-intelligent-platform-management-interface-ipmi)
* [OpenBSD Manual Pages - ipmitool(8) (lanplus / cipher suites)](https://man.openbsd.org/ipmitool.8)
