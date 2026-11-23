# R08 — Telnet attivo

## Cos'è e perché è un rischio
Telnet è un protocollo di amministrazione remota obsoleto che trasmette tutto il traffico, incluse username e password, completamente in chiaro sulla rete. Qualsiasi attaccante in grado di intercettare il traffico (sniffing o Man-in-the-Middle) può leggere le credenziali di accesso e prendere il pieno controllo del server o dell'apparato di rete.

## Come correggere

### Linux (Debian/Ubuntu e RHEL)
1. Disabilitare e fermare il servizio Telnet (`telnet.socket` / `inetd`) e rimuovere il pacchetto server:

    # Debian / Ubuntu
    sudo systemctl disable --now inetd
    sudo apt-get purge -y telnetd inetutils-telnetd

    # RHEL
    sudo systemctl disable --now telnet.socket
    sudo dnf remove -y telnet-server

2. Assicurarsi che sia attivo esclusivamente OpenSSH (`sshd`) per l'amministrazione remota:

    sudo systemctl enable --now ssh

### Cisco IOS / IOS XE
1. Configurare le linee VTY per accettare esclusivamente connessioni SSH ed eliminare Telnet:

    configure terminal
    line vty 0 15
    transport input ssh
    exit
    end
    write memory

### FortiGate (FortiOS)
1. Rimuovere `telnet` dai protocolli consentiti sulle interfacce di gestione via CLI:

    config system interface
        edit "port1"
            set allowaccess ping https ssh
        next
    end

### Switch HPE Aruba (AOS-CX)
1. Disabilitare il server Telnet globalmente e mantenere attivo solo SSH:

    configure terminal
    no telnet-server
    ssh server vrf default
    end
    write memory

### Windows Server
1. Disinstallare la funzionalità Telnet Server tramite PowerShell:

    Uninstall-WindowsFeature -Name Telnet-Server

## Come verificare che sia corretto

### Dalla rete
Da un'altra macchina sulla rete, verificare che la porta TCP 23 sia chiusa tramite `nc` o `nmap`:

    nc -zv -w 2 <IP_TARGET> 23

* Output atteso PRIMA della correzione:
  Connection to <IP_TARGET> 23 port [tcp/telnet] succeeded!

* Output atteso DOPO la correzione:
  nc: connect to <IP_TARGET> port 23 (tcp) failed: Connection refused

### Sulla macchina
* Linux: verificare con `ss -tulpn | grep :23` che nessun processo sia in ascolto sulla porta 23.
* Cisco / Aruba: eseguire `show running-config | include transport input` (Cisco) o `show running-config | include telnet` (Aruba).
* Windows Server: eseguire `Get-WindowsFeature -Name Telnet-Server` e verificare che `InstallState` sia `Available` o `Removed`.

### Verifica in laboratorio (lab/R08-telnet/)
Il laboratorio è disponibile nel percorso lab/R08-telnet/.

* Esecuzione su stato vulnerabile (exit code: 1):
  [*] Controllo porta Telnet (TCP 23) su target...
  [VULNERABILE] Il servizio Telnet (porta 23) è attivo e raggiungibile!

* Esecuzione su stato corretto (exit code: 0):
  [*] Controllo porta Telnet (TCP 23) su target...
  [OK] Porta 23 chiusa (Telnet disabilitato). Configurazione sicura.

## Cosa può rompersi
Script di automazione legacy, vecchi terminali seriali o gestionali interni che si connettono ancora tramite Telnet sulla porta 23 smetteranno di funzionare. Prima di disattivare il servizio, migrare tutti gli script e i client verso SSH (porta 22).

## Fonti
* [Ubuntu Server Documentation — OpenSSH Server](https://ubuntu.com/server/docs/openssh-server)
* [Cisco IOS XE Security Configuration Guide — Configuring Secure Shell (SSH)](https://www.cisco.com/c/en/us/td/docs/ios-xml/ios/sec_usr_ssh/configuration/xe-17/sec-usr-ssh-xe-17-book/sec-secure-shell-v2.html)
* [Fortinet FortiOS CLI Reference — config system interface](https://docs.fortinet.com/document/fortigate/8.0.2/cli-reference/312620/config-system-interface)
* [HPE ArubaOS-CX Security Guide — Telnet / SSH](https://arubanetworking.hpe.com/techdocs/AOS-CX/10.13/PDF/security.pdf)
* [Microsoft Learn — Uninstall-WindowsFeature](https://learn.microsoft.com/en-us/powershell/module/servermanager/uninstall-windowsfeature)
