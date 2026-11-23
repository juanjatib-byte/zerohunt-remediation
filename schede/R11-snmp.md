# R11 — SNMP v1/v2c con community predefinite (public, private)

## Cos'è e perché è un rischio
SNMP v1 e v2c trasmettono le stringhe di autenticazione (*community string*) in chiaro sulla rete e spesso lasciano attivi i valori predefiniti `public` (sola lettura) e `private` (lettura/scrittura). Un attaccante nella rete può interrogare i dispositivi per mappare l'infrastruttura, estrarre configurazioni e routing, o addirittura modificare parametri di sistema se la community `private` è attiva.

## Come correggere

### Linux (Debian/Ubuntu e RHEL)
1. Aprire `/etc/snmp/snmpd.conf` e rimuovere o commentare tutte le righe `rocommunity public` e `rwcommunity private`.
2. Configurare un utente SNMPv3 con autenticazione e cifratura (esempio usato nel laboratorio):
```conf
createUser snmpadmin SHA "AuthPassSicura2026!" AES "PrivPassSicura2026!"
rouser snmpadmin priv
```
3. Riavviare il servizio `snmpd`:
```bash
sudo systemctl restart snmpd
```

### Cisco IOS / IOS XE
1. Rimuovere le community SNMPv1/v2c predefinite e abilitare SNMPv3 con gruppo autenticato e cifrato:
```ios
configure terminal
no snmp-server community public
no snmp-server community private
snmp-server group GRUPPO_SNMPV3 v3 priv
snmp-server user snmpadmin GRUPPO_SNMPV3 v3 auth sha AuthPassSicura2026! priv aes 128 PrivPassSicura2026!
end
write memory
```

### FortiGate (FortiOS)
1. Disabilitare le community SNMPv1/v2c `public` e `private` e configurare un utente SNMPv3 via CLI:
```text
config system snmp community
    delete 1
    delete 2
end
config system snmp user
    edit "snmpadmin"
        set security-level auth-priv
        set auth-proto sha256
        set auth-pwd "AuthPassSicura2026!"
        set priv-proto aes
        set priv-pwd "PrivPassSicura2026!"
    next
end
```

### Switch HPE Aruba (AOS-CX)
1. Rimuovere le community predefinite e configurare SNMPv3 con autenticazione e cifratura:
```text
configure terminal
no snmp-server community public
no snmp-server community private
snmpv3 user snmpadmin auth sha auth-pass plaintext AuthPassSicura2026! priv aes priv-pass plaintext PrivPassSicura2026!
end
write memory
```

### Windows Server
1. Rimuovere le community predefinite e disabilitare o restringere il servizio SNMP tramite PowerShell (preferendo strumenti moderni come CIM/WinRM):
```powershell
Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\ValidCommunities" -Name "public" -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\ValidCommunities" -Name "private" -ErrorAction SilentlyContinue
Restart-Service SNMP
```

## Come verificare che sia corretto

### Dalla rete
Da un'altra macchina sulla rete, interrogare il dispositivo con `snmpwalk` usando la community `public`:
```bash
snmpwalk -v2c -c public -t 2 -r 1 <IP_TARGET> 1.3.6.1.2.1.1.1.0
```
* **Output atteso PRIMA della correzione:**
```text
iso.3.6.1.2.1.1.1.0 = STRING: "Linux ..."
```
* **Output atteso DOPO la correzione:**
```text
Timeout: No Response from <IP_TARGET>
```

### Sulla macchina
* **Linux:** verificare con `grep -E "^(ro|rw)community" /etc/snmp/snmpd.conf` che non ci siano community predefinite e testare SNMPv3 con `snmpwalk -v3 -u snmpadmin -l authPriv -a SHA -A "AuthPassSicura2026!" -x AES -X "PrivPassSicura2026!" localhost 1.3.6.1.2.1.1.1.0`.
* **Cisco / Aruba:** eseguire `show snmp community` (deve risultare vuoto) e `show snmp user`.
* **FortiGate:** eseguire `show system snmp community` e `show system snmp user`.

### Verifica in laboratorio (`lab/R11-snmp/`)
Il laboratorio è disponibile nel percorso `lab/R11-snmp/`.

* **Esecuzione su stato vulnerabile (`exit code: 1`):**
```text
[*] Controllo community SNMP predefinita ('public') su target:161...
[*] Risposta ricevuta: Created directory: /var/lib/snmp/cert_indexes
iso.3.6.1.2.1.1.1.0 = STRING: "Linux 1bf1f20b4256 6.8.0-149-generic #149~22.04.1-Ubuntu SMP PREEMPT_DYNAMIC Wed Oct 28 20:58:45 UTC x86_64"
[VULNERABILE] SNMP risponde con community 'public'!
```

* **Esecuzione su stato corretto (`exit code: 0`):**
```text
[*] Controllo community SNMP predefinita ('public') su target:161...
[*] Risposta ricevuta: Created directory: /var/lib/snmp/cert_indexes
Timeout: No Response from target
[OK] SNMP non risponde alla community predefinita 'public'. Configurazione sicura.
```

## Cosa può rompersi
I sistemi di monitoraggio (es. Zabbix, Nagios, PRTG, LibreNMS) che interrogano l'apparato o il server usando SNMPv1/v2c con `public` smetteranno di raccogliere metriche e segnaleranno il dispositivo come non raggiungibile via SNMP. Prima di applicare la modifica, aggiornare le credenziali su tutti i server di monitoraggio passando a SNMPv3.

## Fonti
* [Net-SNMP Manual — snmpd.conf(5)](https://www.net-snmp.org/docs/man/snmpd.conf.html)
* [Cisco IOS XE — SNMP Configuration Guide](https://www.cisco.com/c/en/us/td/docs/ios-xml/ios/snmp/configuration/xe-17-x/snmp-xe-17-book/nm-snmp-cfg-snmp-support.html)
* [Fortinet FortiOS Administration Guide — SNMP](https://docs.fortinet.com/document/fortigate/8.0.2/administration-guide/62595/snmp)
* [HPE ArubaOS-CX — SNMP Guide](https://arubanetworking.hpe.com/techdocs/AOS-CX/10.13/PDF/snmp_mib.pdf)
* [Microsoft Learn — Configure the Simple Network Management Protocol (SNMP) Service](https://learn.microsoft.com/en-us/troubleshoot/windows-server/networking/configure-snmp-service)
