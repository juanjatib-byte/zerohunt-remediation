# R02 — SMBv1 attivo

## Cos'è e perché è un rischio
SMBv1 (NT1) è una versione obsoleta del protocollo di condivisione file in rete priva di meccanismi moderni di sicurezza e crittografia, esposta a vulnerabilità critiche note come EternalBlue (MS17-010). Se SMBv1 è attivo su un server o una workstation, un attaccante nella rete può sfruttare exploit remoti per eseguire codice arbitrario (RCE) con privilegi di sistema e propagare ransomware nell'intera infrastruttura.

## Come correggere

### Linux (Samba — Debian/Ubuntu e RHEL)
1. Aprire `/etc/samba/smb.conf` e impostare nella sezione `[global]` il protocollo minimo su `SMB2` (o `SMB3`):

    [global]
       server min protocol = SMB2

2. Verificare la sintassi con `testparm` e riavviare il servizio Samba:

    sudo testparm -s && sudo systemctl restart smbd   # Debian/Ubuntu
    sudo testparm -s && sudo systemctl restart smb    # RHEL

### Windows Server / Client (PowerShell)
1. Disabilitare il protocollo SMBv1 lato server tramite PowerShell con privilegi di amministratore:

    Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force

2. Rimuovere la funzionalità SMB 1.0/CIFS File Sharing Support (richiede riavvio):

    Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart

## Come verificare che sia corretto

### Dalla rete
Da un'altra macchina sulla rete, verificare con `nmap` o `smbclient` che SMBv1 sia disabilitato:

    nmap -p 445 --script smb-protocols <IP_TARGET>

* Output atteso PRIMA della correzione:
  NT LM 0.12 (SMBv1) [dangerous, but default]

* Output atteso DOPO la correzione:
  Nessuna voce NT LM 0.12 (SMBv1); presenti solo SMB 2.02 / 2.1 / 3.x.

### Sulla macchina
* Linux (Samba): eseguire `testparm -s 2>/dev/null | grep "server min protocol"` e verificare che restituisca `SMB2` (o `SMB3`).
* Windows Server: eseguire `Get-SmbServerConfiguration | Select-Object EnableSMB1Protocol` e verificare che restituisca `False`.

### Verifica in laboratorio (lab/R02-smbv1/)
Il laboratorio è disponibile nel percorso lab/R02-smbv1/.

* Esecuzione su stato vulnerabile (exit code: 1):
  [*] Controllo supporto SMBv1 (NT1) su target:445...
  [VULNERABILE] Il server accetta connessioni con SMBv1 (NT1)!

* Esecuzione su stato corretto (exit code: 0):
  [*] Controllo supporto SMBv1 (NT1) su target:445...
  [OK] SMBv1 (NT1) rifiutato dal server. Configurazione sicura.

## Cosa può rompersi
Stampanti multifunzione molto vecchie (scansione su cartella di rete SMB), NAS datati, macchinari industriali o sistemi Windows XP / Server 2003 che supportano esclusivamente SMBv1 non riusciranno più ad accedere alle condivisioni di rete. Prima di disattivare SMBv1 in produzione, attivare l'auditing degli accessi SMBv1 per identificare eventuali client legacy ancora attivi.

## Fonti
* [Samba Wiki — smb.conf (server min protocol)](https://www.samba.org/samba/docs/current/man-html/smb.conf.5.html#SERVERMINPROTOCOL)
* [Microsoft Learn — How to detect, enable, and disable SMBv1, SMBv2, and SMBv3 in Windows](https://learn.microsoft.com/en-us/windows-server/storage/file-server/troubleshoot/detect-enable-and-disable-smbv1-v2-v3)
