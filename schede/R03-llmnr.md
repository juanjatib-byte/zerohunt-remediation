# R03 — LLMNR attivo

## Cos'è e perché è un rischio
LLMNR (*Link-Local Multicast Name Resolution*) è un protocollo utilizzato da Windows per risolvere i nomi degli host sulla rete locale quando il DNS fallisce. Poiché LLMNR trasmette richieste in multicast senza autenticazione, un attaccante sulla stessa sottorete (es. tramite strumenti come Responder) può rispondere alle richieste spacciandosi per l'host cercato e catturare gli hash delle credenziali NTLMv2 dell'utente per poi effettuare attacchi di *cracking* offline o *SMB Relay*.

## Come correggere

### Windows Server / Client (PowerShell — Registro di sistema)
1. Disabilitare la risoluzione dei nomi multicast LLMNR impostando `EnableMulticast` su `0` tramite PowerShell con privilegi di amministratore:

    New-Item "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" -Force | Out-Null
    New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" -Name "EnableMulticast" -Value 0 -PropertyType "DWord" -Force | Out-Null

### Active Directory (Group Policy — GPO)
1. Aprire la **Group Policy Management Console** (`gpmc.msc`), modificare una GPO applicata ai sistemi del dominio e abilitare la seguente impostazione in `Computer Configuration -> Administrative Templates -> Network -> DNS Client`:

    Turn off multicast name resolution -> Enabled

2. Forzare l'aggiornamento delle policy sui client e server:

    gpupdate /force

## Come verificare che sia corretto

### Dalla rete
Da un'altra macchina sulla rete locale, avviare un ascoltatore passivo (es. Responder in modalità analisi `-A`) oppure catturare il traffico UDP sulla porta `5355` (multicast `224.0.0.252`) durante una richiesta verso un nome host inesistente:

    tcpdump -i eth0 udp port 5355

* Output atteso PRIMA della correzione:
  Pacchetti UDP indirizzati a `224.0.0.252:5355` (query LLMNR).

* Output atteso DOPO la correzione:
  Nessun pacchetto LLMNR inviato sulla porta UDP 5355.

### Sulla macchina
Su Windows Server / Client, verificare via PowerShell che il valore `EnableMulticast` sia impostato su `0`:

    Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" -Name "EnableMulticast"

* Output atteso dopo la correzione:
  EnableMulticast : 0

## Cosa può rompersi
In reti domestiche o piccoli uffici privi di un server DNS interno correttamente configurato, i computer Windows potrebbero non riuscire più a risolvere i nomi NetBIOS/locali di altri PC o stampanti di rete usando solo il nome breve (es. `\\PC-UFFICIO`), richiedendo l'uso dell'FQDN DNS oppure dell'indirizzo IP diretto.

## Fonti
* [Microsoft Learn — Policy CSP DNSClient (TurnOffMulticastNameResolution)](https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-admx-dnsclient)
* [Microsoft Learn — Securing Domain Controllers Against Attack (LLMNR & NetBIOS)](https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/plan/security-best-practices/securing-domain-controllers-against-attack)

