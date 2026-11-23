# R04 — NetBIOS Name Service attivo

## Cos'è e perché è un rischio
Il servizio **NetBIOS Name Service (NBT-NS)** opera sulla porta UDP 137 e viene utilizzato dai sistemi Windows come meccanismo di fallback quando il DNS e LLMNR non riescono a risolvere un nome host. Poiché NBT-NS funziona tramite trasmissioni broadcast prive di autenticazione, un attaccante sulla stessa rete locale può rispondere alle richieste spacciandosi per la risorsa richiesta e intercettare gli hash delle credenziali NTLMv2 per eseguire attacchi di *cracking* o *NTLM Relay*.

## Come correggere

### Windows Server / Client (PowerShell — WMI / CIM)
1. Disabilitare NetBIOS over TCP/IP (`TcpipNetbiosOptions = 2`) su tutte le schede di rete attive tramite PowerShell con privilegi di amministratore:

    Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration -Filter "IPEnabled = True" | Invoke-CimMethod -MethodName SetTcpipNetbios -Arguments @{ TcpipNetbiosOptions = [uint32]2 }

### Windows Server / Client (Registro di sistema per interfaccia)
1. In alternativa, impostare il parametro `NetbiosOptions` sul valore `2` (*Disable NetBIOS over TCP/IP*) sotto ciascuna interfaccia di rete nel registro:

    Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces" | ForEach-Object { Set-ItemProperty -Path $_.PSPath -Name "NetbiosOptions" -Value 2 }

### DHCP Server (Windows Server)
1. Per disabilitare NBT-NS centralmente su tutti i client DHCP, configurare l'opzione vendor Microsoft **001 Microsoft Disable Netbios Option** impostando il valore esadecimale `0x2` nello scope DHCP.

## Come verificare che sia corretto

### Dalla rete
Da un'altra macchina sulla rete locale, catturare il traffico broadcast sulla porta UDP `137` oppure interrogare l'host con `nmap`:

    nmap -sU -p 137 --script nbstat <IP_TARGET>

* Output atteso PRIMA della correzione:
  137/udp open netbios-ns (risposta con nome NetBIOS e gruppo di lavoro).

* Output atteso DOPO la correzione:
  137/udp closed (nessuna risposta NetBIOS).

### Sulla macchina
Su Windows Server / Client, verificare via PowerShell che `TcpipNetbiosOptions` sia impostato su `2` per tutte le schede di rete abilitate:

    Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration -Filter "IPEnabled = True" | Select-Object Description, TcpipNetbiosOptions

* Output atteso dopo la correzione:
  TcpipNetbiosOptions : 2

## Cosa può rompersi
Applicazioni legacy molto datate basate su NetBIOS/WINS, vecchi file server Windows NT / 2003 o dispositivi di rete obsoleti che non utilizzano DNS potrebbero non essere più raggiungibili tramite il solo nome breve NetBIOS. Prima di applicare la modifica, assicurarsi che tutti gli host interni siano registrati correttamente nel server DNS aziendale.

## Fonti
* [Microsoft Learn — SetTcpipNetbios method in class Win32_NetworkAdapterConfiguration](https://learn.microsoft.com/en-us/windows/win32/cimwin32prov/settcpipnetbios-method-in-class-win32-networkadapterconfiguration)
* [Microsoft Learn — Unsecure network protocols assessment (LLMNR / NBT-NS)](https://learn.microsoft.com/en-us/troubleshoot/windows-server/networking/disable-netbios-tcp-ip-using-dhcp)

