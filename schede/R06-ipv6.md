# R06 — IPv6 attivo ma non gestito (DHCPv6 / router advertisement non protetti)

## Cos'è e perché è un rischio
Nei sistemi operativi moderni (Windows e Linux) IPv6 è abilitato di default con priorità superiore rispetto a IPv4. Se l'infrastruttura aziendale non gestisce né monitora IPv6 (mancanza di DNSv6 interno, firewalling IPv6 e protezione RA Guard sugli switch), un attaccante sulla rete locale (es. tramite strumenti come mitm6) può inviare pacchetti *Router Advertisement (RA)* o risposte *DHCPv6* rogue, assegnando il proprio host come server DNS IPv6 delle vittime per intercettare il traffico e catturare credenziali NTLM/Kerberos.

## Come correggere

### Windows Server / Client (PowerShell)
1. Se IPv6 non è utilizzato nell'infrastruttura, disabilitare il componente `ms_tcpip6` sulle schede di rete oppure impostare la preferenza di IPv4 su IPv6 (`DisabledComponents = 0x20` o `0xff`) tramite PowerShell con privilegi di amministratore:

    # Preferire IPv4 rispetto a IPv6 (raccomandato da Microsoft)
    New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" -Name "DisabledComponents" -Value 0x20 -PropertyType "DWord" -Force | Out-Null

    # Oppure disabilitare il binding IPv6 sulle singole interfacce di rete non gestite
    Disable-NetAdapterBinding -Name "*" -ComponentID ms_tcpip6

### Linux (Debian/Ubuntu e RHEL — sysctl)
1. Se IPv6 non è utilizzato, disabilitarlo tramite parametri del kernel in `/etc/sysctl.d/99-disable-ipv6.conf` (oppure bloccare l'accettazione dei *Router Advertisement* con `accept_ra = 0` se IPv6 è usato in modalità statica):

    cat << 'INNER_EOF' | sudo tee /etc/sysctl.d/99-disable-ipv6.conf
    net.ipv6.conf.all.disable_ipv6 = 1
    net.ipv6.conf.default.disable_ipv6 = 1
    net.ipv6.conf.all.accept_ra = 0
    net.ipv6.conf.default.accept_ra = 0
    INNER_EOF

2. Applicare immediatamente i parametri del kernel:

    sudo sysctl --system

### Rete — Switch Cisco IOS / IOS XE (IPv6 RA Guard e DHCPv6 Guard)
1. Abilitare **IPv6 RA Guard** sulle porte di accesso (*access port*) degli switch per bloccare i *Router Advertisement* provenienti da host non autorizzati:

    configure terminal
    ipv6 nd raguard policy HOST_POLICY
     device-role host
    exit
    interface range GigabitEthernet1/0/1 - 48
     ipv6 nd raguard attach-policy HOST_POLICY
    end
    write memory

## Come verificare che sia corretto

### Dalla rete
Da un'altra macchina sulla rete locale, verificare che gli host non inviino richieste DHCPv6 (UDP 546/547) né acquisiscano indirizzi IPv6 temporanei o DNSv6 da sorgenti non autorizzate:

    tcpdump -i eth0 ip6 and \(udp port 546 or udp port 547 or icmp6\)

* Output atteso PRIMA della correzione:
  Pacchetti DHCPv6 Solicit/Advertise e Router Solicitation/Advertisement attivi sulle interfacce non gestite.

* Output atteso DOPO la correzione:
  Nessun indirizzo IPv6 autoconfigurato (SLAAC/DHCPv6) sulle interfacce host e pacchetti RA rogue bloccati dallo switch.

### Sulla macchina
* Windows Server / Client: eseguire `Get-NetAdapterBinding -ComponentID ms_tcpip6` (deve risultare `Enabled : False`) oppure verificare `DisabledComponents` sotto `Tcpip6\Parameters`.
* Linux: eseguire `sysctl net.ipv6.conf.all.disable_ipv6 net.ipv6.conf.all.accept_ra` e verificare che restituiscano `1` e `0` (oppure `ip -6 addr` senza indirizzi globali/link-local non gestiti).
* Switch Cisco: eseguire `show ipv6 nd raguard policy HOST_POLICY`.

## Cosa può rompersi
Alcuni ruoli di Windows Server (come Exchange Server, DirectAccess o cluster Failover) richiedono che il componente IPv6 di loopback rimanga attivo per le comunicazioni interne: in tali casi Microsoft raccomanda di preferire IPv4 su IPv6 (`DisabledComponents = 0x20`) anziché disabilitare completamente `ms_tcpip6`. Inoltre, su Linux servizi come Postfix, Nginx o Java configurati esplicitamente per ascoltare su `[::]` potrebbero generare avvisi all'avvio se IPv6 viene disattivato a livello kernel.

## Fonti
* [Microsoft Learn — Guidance for configuring IPv6 in Windows for advanced users](https://learn.microsoft.com/en-us/troubleshoot/windows-server/networking/configure-ipv6-in-windows)
* [Linux Kernel Documentation — IP Sysctl (net.ipv6.conf)](https://docs.kernel.org/networking/ip-sysctl.html)
* [Cisco IOS XE — IPv6 First-Hop Security Configuration Guide (RA Guard)](https://www.cisco.com/c/en/us/td/docs/ios-xml/ios/ipv6_fhsec/configuration/xe-16/ip6f-xe-16-book/ip6-ra-guard.html)
