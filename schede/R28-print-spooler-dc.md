# R28 - Servizio Print Spooler attivo sui domain controller

## Cos'è e perché è un rischio
Mantenere attivo il servizio **Print Spooler (`Spooler`)** sui **Domain Controller Active Directory** espone l'intero dominio ad attacchi critici di esecuzione remota e coercizione dell'autenticazione:
- **PrintNightmare (CVE-2021-1675 / CVE-2021-34527):** consente a qualsiasi utente autenticato di installare driver di stampa malevoli sul Domain Controller ottenendo esecuzione di codice remoto (`RCE`) con privilegi `NT AUTHORITY\SYSTEM`.
- **Authentication Coercion (PrinterBug / SpoolSample):** un attaccante può forzare il Domain Controller ad autenticarsi verso un host controllato dall'attaccante via SMB/HTTP, permettendo attacchi **NTLM Relay** contro AD CS (ESC8) o altri server critici.
- **Superficie d'attacco inutile:** un Domain Controller non deve mai fungere da server di stampa.

## Come verificare il problema
```powershell
Get-Service -Name Spooler | Select-Object Name, Status, StartType
```
*Output atteso PRIMA della correzione (se vulnerabile):* `Status : Running` e `StartType : Automatic`.

## Come rimediare (Remediation)

1. **Arrestare e disabilitare il servizio `Spooler` tramite PowerShell** su tutti i Domain Controller:
```powershell
Stop-Service -Name Spooler -Force
Set-Service -Name Spooler -StartupType Disabled
```
2. **Applicare la disabilitazione via Group Policy (GPO)** nella OU *Domain Controllers*:
   - *Computer Configuration* -> *Policies* -> *Windows Settings* -> *Security Settings* -> *System Services* -> **Print Spooler** -> impostare **Define this policy setting** = **Disabled**.
3. **Bloccare inoltre le connessioni client remote al servizio di stampa via GPO:** *Computer Configuration* -> *Administrative Templates* -> *Printers* -> **Allow Print Spooler to accept client connections** = **Disabled**.

## Come verificare che sia corretto
```powershell
Get-Service -Name Spooler | Select-Object Name, Status, StartType
```
*Output atteso DOPO la correzione:* `Status : Stopped` e `StartType : Disabled`.

## Cosa può rompersi
- Eventuali stampanti condivise direttamente dal Domain Controller (pratica sconsigliata) o flussi di stampa PDF virtuali/script di stampa eseguiti localmente sul DC smetteranno di funzionare e dovranno essere migrati su un **Print Server dedicato** separato.

## Fonti
* [Microsoft Learn - Defender for Identity: Disable Print Spooler service on domain controllers](https://learn.microsoft.com/en-us/defender/identity/security-assessment-print-spooler)
* [Microsoft Support - KB5005010: Mitigating the PrintNightmare vulnerability](https://support.microsoft.com/en-us/topic/kb5005010-mitigating-the-printnightmare-vulnerability-31c6f4ec-5bc1-9a1a-f5ec-2d9aa1e366a6)
