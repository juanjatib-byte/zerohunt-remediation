# R05 — WPAD / rilevamento automatico proxy attivo

## Cos'è e perché è un rischio
WPAD (*Web Proxy Auto-Discovery*) consente ai sistemi Windows e ai browser di individuare automaticamente un file di configurazione proxy (`wpad.dat`) tramite DHCP o risoluzione DNS/LLMNR/NBT-NS. Se WPAD è attivo senza controllo, un attaccante nella stessa rete locale può rispondere alle richieste per l'host `wpad` (spoofing DNS/LLMNR/NBT-NS) e fornire uno script PAC malevolo, dirottando tutto il traffico HTTP/HTTPS della vittima verso un proxy controllato dall'attaccante o richiedendo autenticazione NTLM per catturarne gli hash.

## Come correggere

### Windows Server / Client (PowerShell — Disabilitazione servizio WinHttpAutoProxySvc e registro)
1. Disabilitare il rilevamento automatico del proxy nelle impostazioni di rete dell'utente e del sistema tramite PowerShell con privilegi di amministratore:

    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name "AutoDetect" -Value 0
    New-Item "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Internet Settings" -Force | Out-Null
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Internet Settings" -Name "ProxySettingsPerUser" -Value 0

2. Disabilitare il servizio **WinHTTP Web Proxy Auto-Discovery Service** (`WinHttpAutoProxySvc`) tramite registro:

    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\WinHttpAutoProxySvc" -Name "Start" -Value 4

3. Riavviare il sistema per arrestare completamente il servizio.

### Active Directory (Group Policy — GPO)
1. Aprire la **Group Policy Management Console** (`gpmc.msc`), modificare una GPO applicata ai sistemi del dominio e impostare su **Disabilitato** (*Disabled*) il rilevamento automatico delle impostazioni proxy in `Computer Configuration -> Administrative Templates -> Windows Components -> Internet Explorer`:

    Turn off Automatic Proxy Configuration -> Enabled (oppure disabilitare "Automatically detect settings" nelle preferenze Internet)

2. Forzare l'aggiornamento delle policy:

    gpupdate /force

## Come verificare che sia corretto

### Dalla rete
Da un'altra macchina sulla rete locale, catturare il traffico DNS/LLMNR/NBT-NS durante l'avvio di un browser o una richiesta HTTP per verificare che non vengano inviate query per il nome `wpad`:

    tcpdump -i eth0 port 53 or port 5355 or port 137

* Output atteso PRIMA della correzione:
  Richieste di risoluzione del nome `wpad` o `wpad.<dominio>` e download di `http://wpad.<dominio>/wpad.dat`.

* Output atteso DOPO la correzione:
  Nessuna query di risoluzione per `wpad` né richieste HTTP verso `/wpad.dat`.

### Sulla macchina
Su Windows Server / Client, verificare via PowerShell che `AutoDetect` sia `0` e che `WinHttpAutoProxySvc` sia disabilitato (`Start = 4`):

    Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name "AutoDetect"
    Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\WinHttpAutoProxySvc" -Name "Start"

* Output atteso dopo la correzione:
  AutoDetect : 0
  Start      : 4

## Cosa può rompersi
Negli ambienti aziendali che utilizzano intenzionalmente WPAD (tramite server DHCP opzione 252 o record DNS `wpad` legittimo) per configurare automaticamente il proxy aziendale sui laptop degli utenti, i browser e le applicazioni perderanno l'accesso a Internet finché non verrà configurato un proxy esplicito (indirizzo IP/porta statici) o un file PAC tramite URL diretto via GPO.

## Fonti
* [Microsoft Security Bulletin MS16-077 — Security Update for WPAD (3165191)](https://learn.microsoft.com/en-us/security-updates/securitybulletins/2016/ms16-077)
* [Microsoft Learn — WinHTTP AutoProxy Support](https://learn.microsoft.com/en-us/windows/win32/winhttp/winhttp-autoproxy-support)
