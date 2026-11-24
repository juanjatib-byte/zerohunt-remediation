# R27 - Account AD con preautenticazione Kerberos disattivata

## Cos'è e perché è un rischio
Disattivare l'opzione **Kerberos Preauthentication** (`DONT_REQ_PREAUTH` / flag UAC `0x400000`) su un account utente in Active Directory espone il dominio all'attacco **AS-REP Roasting**:
- **Recupero hash senza autenticazione:** qualsiasi utente in rete (anche senza credenziali di dominio) può inviare una richiesta `AS-REQ` per l'account vulnerabile; il Domain Controller risponde immediatamente con un `AS-REP` contenente una parte cifrata con l'hash NTLM della password dell'utente.
- **Cracking offline della password:** l'attaccante può estrarre il ticket (`GetNPUsers.py` / Rubeus) e sottoporlo a cracking offline su GPU con Hashcat (`-m 18200`) senza generare alcun blocco account (account lockout) su Active Directory.
- **Compromissione del dominio:** se l'account ha privilegi elevati o appartiene a gruppi amministrativi, l'intero dominio Active Directory può essere compromesso.

## Come verificare il problema
```powershell
Get-ADUser -Filter 'DoesNotRequirePreAuth -eq $true' -Properties DoesNotRequirePreAuth | Select-Object Name, SamAccountName, DoesNotRequirePreAuth
```
*Output atteso PRIMA della correzione (se vulnerabile):* elenco di uno o più utenti con `DoesNotRequirePreAuth : True`.

## Come rimediare (Remediation)

1. **Riattivare la preautenticazione Kerberos tramite PowerShell** su tutti gli account individuati:
```powershell
Get-ADUser -Filter 'DoesNotRequirePreAuth -eq $true' | Set-ADAccountControl -DoesNotRequirePreAuth $false
```
2. **Via interfaccia grafica (`dsa.msc` - Active Directory Users and Computers):** aprire le *Proprietà* dell'utente -> scheda **Account** -> sotto *Opzioni account*, **deselezionare** la casella **"Non richiedere la preautenticazione Kerberos"** -> *Applica*.
3. **Ruotare immediatamente la password** degli account che avevano il flag attivo (impostando una password robusta > 16 caratteri), poiché l'hash potrebbe già essere stato catturato in precedenza.

## Come verificare che sia corretto
```powershell
Get-ADUser -Filter 'DoesNotRequirePreAuth -eq $true'
```
*Output atteso DOPO la correzione:* nessun risultato restituito (output vuoto).

## Cosa può rompersi
- Applicazioni legacy molto vecchie o sistemi non-Windows che implementano stack Kerberos obsoleti privi di supporto `PA-ENC-TIMESTAMP` (preautenticazione RFC 4120) potrebbero non riuscire più ad autenticarsi con quell'account finché non vengono aggiornate.

## Fonti
* [Microsoft Learn - Set-ADAccountControl (-DoesNotRequirePreAuth)](https://learn.microsoft.com/en-us/powershell/module/activedirectory/set-adaccountcontrol)
* [MITRE ATT&CK T1558.004 - Steal or Forge Kerberos Tickets: AS-REP Roasting](https://attack.mitre.org/techniques/T1558/004/)
