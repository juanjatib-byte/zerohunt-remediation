# R22 — DNS: trasferimento di zona (AXFR) permesso

## Cos'è e perché è un rischio
Il trasferimento di zona DNS (AXFR) serve a replicare l'intero database dei record DNS da un server primario a uno secondario. Se il server DNS consente richieste AXFR a qualsiasi indirizzo IP, un attaccante può scaricare in un solo comando l'elenco completo di tutti gli host, server interni, domain controller e indirizzi IP dell'organizzazione, facilitando enormemente la fase di ricognizione e gli attacchi successivi.

## Come correggere

### Linux (BIND9 — Debian/Ubuntu e RHEL)
1. Aprire il file di configurazione di BIND9 (`/etc/bind/named.conf.options` su Debian/Ubuntu oppure `/etc/named.conf` su RHEL) e limitare `allow-transfer` esclusivamente agli IP dei server DNS secondari autorizzati oppure a `none` se non ci sono secondari:

    options {
        allow-transfer { none; };
        // Oppure solo verso i DNS secondari autorizzati:
        // allow-transfer { 10.10.10.2; };
    };

2. Verificare la sintassi e ricaricare BIND9:

    sudo named-checkconf && sudo systemctl reload bind9   # Debian/Ubuntu
    sudo named-checkconf && sudo systemctl reload named   # RHEL

### Windows Server (DNS Server)
1. Disabilitare o limitare il trasferimento di zona alle sole macchine presenti nella scheda Name Server (NS) della zona tramite PowerShell:

    Set-DnsServerPrimaryZone -Name "zerohunt.local" -SecureSecondaries TransferToZoneNameServer

### FortiGate (FortiOS DNS Database)
1. Disabilitare il trasferimento di zona AXFR sulla zona DNS configurata sul firewall via CLI:

    config system dns-database
        edit "zerohunt.local"
            set allow-transfer disable
        next
    end

## Come verificare che sia corretto

### Dalla rete
Da un'altra macchina sulla rete non autorizzata, tentare una richiesta AXFR con `dig`:

    dig @<IP_TARGET> <DOMINIO> AXFR

* Output atteso PRIMA della correzione:
  Elenco completo dei record SOA, NS, A, CNAME e MX della zona.

* Output atteso DOPO la correzione:
  ; Transfer failed.

### Sulla macchina
* Linux (BIND9): verificare con `grep -rn "allow-transfer" /etc/bind/ /etc/named* 2>/dev/null` che sia impostato su `none` o sugli IP dei soli DNS secondari.
* Windows Server: eseguire `Get-DnsServerZone -Name "<DOMINIO>" | Select-Object ZoneName, SecureSecondaries`.

### Verifica in laboratorio (lab/R22-dns-axfr/)
Il laboratorio è disponibile nel percorso lab/R22-dns-axfr/.

* Esecuzione su stato vulnerabile (exit code: 1):
  [*] Controllo trasferimento di zona DNS (AXFR) su target per zerohunt.local...
  [VULNERABILE] Trasferimento di zona AXFR permesso! Record estratti:
  zerohunt.local.		60	IN	SOA	ns1.zerohunt.local. admin.zerohunt.local. 1 60 60 60 60
  zerohunt.local.		60	IN	NS	ns1.zerohunt.local.
  db-interna.zerohunt.local. 60	IN	A	10.10.10.20
  dc01.zerohunt.local.	60	IN	A	10.10.10.10
  ns1.zerohunt.local.	60	IN	A	127.0.0.1
  zerohunt.local.		60	IN	SOA	ns1.zerohunt.local. admin.zerohunt.local. 1 60 60 60 60

* Esecuzione su stato corretto (exit code: 0):
  [*] Controllo trasferimento di zona DNS (AXFR) su target per zerohunt.local...
  [OK] Trasferimento di zona AXFR rifiutato. Configurazione sicura.

## Cosa può rompersi
I server DNS secondari (slave) il cui indirizzo IP non è stato inserito esplicitamente nell'elenco `allow-transfer` (o nei record NS della zona su Windows Server) non riceveranno più gli aggiornamenti dei record DNS e, allo scadere del timer di *Expiry* del record SOA, smetteranno di rispondere alle query per quel dominio. Verificare sempre gli IP di tutti i DNS secondari prima di restringere il trasferimento.

## Fonti
* [ISC BIND 9 Administrator Reference Manual — allow-transfer](https://bind9.readthedocs.io/en/latest/reference.html#namedconf-statement-allow-transfer)
* [Microsoft Learn — Set-DnsServerPrimaryZone](https://learn.microsoft.com/en-us/powershell/module/dnsserver/set-dnsserverprimaryzone)
* [Fortinet FortiOS CLI Reference — config system dns-database](https://docs.fortinet.com/document/fortigate/8.0.2/cli-reference/471620/config-system-dns-database)
