# R07 - RDP esposto senza NLA

## Cos'è e perché è un rischio
Il protocollo **RDP (Remote Desktop Protocol, porta TCP 3389)** consente l'accesso grafico remoto ai sistemi Windows. Quando è configurato senza **NLA (Network Level Authentication)**, il server carica l'intera schermata di login grafico di Windows prima ancora che l'utente venga autenticato.

Questo espone l'infrastruttura a rischi critici:
- **Vulnerabilità pre-autenticazione:** exploit remoti sullo stack RDP raggiungibili senza credenziali (es. CVE-2019-0708 *BlueKeep*).
- **Denial of Service (DoS):** esaurimento di RAM e CPU del server tramite apertura massiva di sessioni grafiche non autenticate.
- **Brute-force diretto:** possibilità di tentare password direttamente sull'interfaccia grafica di Windows.

## Come verificare il problema

### Dalla rete
Utilizzare `nmap` da una macchina Linux per enumerare i livelli di sicurezza negoziati dal servizio RDP:
```bash
nmap -p 3389 --script rdp-enum-encryption <IP_TARGET>
```
*Output atteso se vulnerabile:*
```text
| rdp-enum-encryption:
|   Security layer
|     CredSSP (NLA): SUCCESS
|     Native RDP: SUCCESS
|     SSL: SUCCESS
```
*(La presenza di `Native RDP: SUCCESS` o `SSL: SUCCESS` indica che il server accetta connessioni senza obbligo di NLA).*

### Sulla macchina Windows
Verificare tramite PowerShell il valore della proprietà `UserAuthenticationRequired`:
```powershell
(Get-WmiObject -Class "Win32_TSGeneralSetting" -Namespace root\cimv2\terminalservices -Filter "TerminalName='RDP-tcp'").UserAuthenticationRequired
```
*Output atteso PRIMA della correzione:* `0`

## Come rimediare (Remediation)

### PowerShell (locale / script)
Eseguire PowerShell come Amministratore per rendere obbligatoria l'autenticazione a livello di rete:
```powershell
$ts = Get-WmiObject -Class "Win32_TSGeneralSetting" -Namespace root\cimv2\terminalservices -Filter "TerminalName='RDP-tcp'"
$ts.SetUserAuthenticationRequired(1)
```

### Active Directory (Group Policy - GPO)
1. Aprire la **Group Policy Management Console** (`gpmc.msc`) e modificare una GPO applicata ai server/workstation:
   `Computer Configuration -> Policies -> Administrative Templates -> Windows Components -> Remote Desktop Services -> Remote Desktop Session Host -> Security`
2. Impostare su **Enabled** la policy:
   `Require user authentication for remote connections by using Network Level Authentication`
3. Applicare l'aggiornamento sulle macchine target:
   ```cmd
   gpupdate /force
   ```

### Hardening di rete
Non esporre mai la porta TCP `3389` direttamente su Internet; incapsulare l'accesso remoto tramite **VPN** o **RD Gateway** e filtrare il traffico tramite firewall.

## Come verificare che sia corretto

### Dalla rete
Rieseguire la scansione con `nmap`:
```bash
nmap -p 3389 --script rdp-enum-encryption <IP_TARGET>
```
*Output atteso DOPO la correzione:*
```text
| rdp-enum-encryption:
|   Security layer
|     CredSSP (NLA): SUCCESS
```
*(Solo `CredSSP (NLA)` risulta attivo; i livelli non autenticati sono disabilitati).*

### Sulla macchina Windows
```powershell
(Get-WmiObject -Class "Win32_TSGeneralSetting" -Namespace root\cimv2\terminalservices -Filter "TerminalName='RDP-tcp'").UserAuthenticationRequired
```
*Output atteso DOPO la correzione:* `1`

## Cosa può rompersi
Client RDP molto obsoleti (es. Windows XP SP2 o versioni precedenti, vecchi thin client Linux/embedded non aggiornati con `FreeRDP`/`rdesktop` datati) che non supportano il protocollo **CredSSP** non riusciranno più a collegarsi al server. Inoltre, se il client non riesce a contattare un Domain Controller per ottenere un ticket Kerberos durante la fase NLA, l'autenticazione può fallire (in tal caso viene usato NTLM come fallback se consentito).

## Fonti
* [Microsoft Learn - Configure Network Level Authentication for Remote Desktop Services Connections](https://microsoft.com)
* [CIS Microsoft Windows Server Benchmark - Ensure 'Require user authentication for remote connections by using Network Level Authentication' is set to 'Enabled'](https://cisecurity.org)
