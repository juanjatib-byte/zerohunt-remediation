# R01 — Firma SMB non obbligatoria

## Cos'è e perché è un rischio
La firma digitale SMB (*SMB Signing*) garantisce l'integrità e l'autenticità dei pacchetti scambiati tramite il protocollo di condivisione file SMB. Quando la firma SMB non è obbligatoria sul server o sul client, un attaccante nella rete locale può intercettare il traffico e compiere attacchi di tipo *SMB Relay* (inoltrando le credenziali NTLM verso altri sistemi della rete) oppure alterare i pacchetti in transito.

## Come correggere

### Windows Server / Client (PowerShell)
1. Abilitare l'obbligo di firma SMB sia lato server (`RequireSecuritySignature`) che lato client tramite PowerShell con privilegi di amministratore:

    Set-SmbServerConfiguration -RequireSecuritySignature $true -Force
    Set-SmbClientConfiguration -RequireSecuritySignature $true -Force

### Active Directory (Group Policy — GPO)
1. Aprire la **Group Policy Management Console** (`gpmc.msc`), modificare una GPO applicata ai server/workstation (oppure la *Default Domain Policy*) e impostare su **Abilitato** (*Enabled*) le seguenti policy in `Computer Configuration -> Policies -> Windows Settings -> Security Settings -> Local Policies -> Security Options`:

    Microsoft network server: Digitally sign communications (always) -> Enabled
    Microsoft network client: Digitally sign communications (always) -> Enabled

2. Forzare l'aggiornamento delle policy sui sistemi target:

    gpupdate /force

## Come verificare che sia corretto

### Dalla rete
Da un'altra macchina sulla rete (es. Linux con `nmap`), verificare che la firma SMB risulti obbligatoria (`Message signing enabled and required`):

    nmap -p 445 --script smb2-security-mode <IP_TARGET>

* Output atteso PRIMA della correzione:
  Message signing enabled but not required

* Output atteso DOPO la correzione:
  Message signing enabled and required

### Sulla macchina
Su Windows Server / Client, verificare via PowerShell che `RequireSecuritySignature` sia impostato su `True` sia per il server che per il client:

    Get-SmbServerConfiguration | Select-Object EnableSecuritySignature, RequireSecuritySignature
    Get-SmbClientConfiguration | Select-Object EnableSecuritySignature, RequireSecuritySignature

* Output atteso dopo la correzione:
  EnableSecuritySignature RequireSecuritySignature
  ----------------------- ------------------------
                     True                     True

## Cosa può rompersi
Dispositivi legacy molto datati (es. vecchie stampanti multifunzione con scansione su cartella di rete SMB, NAS obsoleti, sistemi Windows XP / Server 2003 o client Samba molto vecchi configurati senza firma) che non supportano SMB Signing non riusciranno più ad accedere alle condivisioni di rete. Inoltre, l'abilitazione della firma comporta un lieve sovraccarico della CPU sui file server con traffico molto elevato.

## Fonti
* [Microsoft Learn — Overview of Server Message Block signing](https://learn.microsoft.com/en-us/windows-server/storage/file-server/smb-signing)
* [Microsoft Learn — Set-SmbServerConfiguration (PowerShell)](https://learn.microsoft.com/en-us/powershell/module/smbshare/set-smbserverconfiguration)
