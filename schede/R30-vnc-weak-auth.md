# R30 - VNC senza password o con password debole

## Cos'è e perché è un rischio
Esporre server **VNC (Virtual Network Computing, porte TCP 5900+)** senza autenticazione (`SecurityTypes=None`) o protetti esclusivamente dalla tradizionale autenticazione **VNCAuth (DES truncata a 8 caratteri)** senza cifratura di trasporto espone l'intera sessione grafica:
- **Accesso grafico completo immediato:** se VNC non richiede password, chiunque raggiunga la porta `5900` prende il controllo completo del desktop e del sistema.
- **Autenticazione debole e traffico non cifrato (RFC 6143):** il meccanismo VNCAuth classico tronca le password a 8 caratteri, è vulnerabile al brute-force rapido e trasmette lo schermo e i tasti digitati in chiaro sulla rete (sniffing / MITM).

## Come verificare il problema
```bash
nmap -p 5900-5905 --script vnc-info,vnc-brute <IP_TARGET>
```
*Output atteso PRIMA della correzione (se vulnerabile):* `Security types: None (1)` oppure `VNC Authentication (2)` con password debole individuata e servizio esposto su `0.0.0.0:5900`.

## Come rimediare (Remediation)

1. **Impostare una password VNC robusta** con `vncpasswd` e configurare **TigerVNC** affinché ascolti esclusivamente su `localhost` (`127.0.0.1`) utilizzando **VeNCrypt (TLS)** anziché `VncAuth` in chiaro:
```bash
vncpasswd
cat << 'CONF' > ~/.vnc/config
localhost
SecurityTypes=VeNCrypt,TLSVnc
CONF
systemctl restart vncserver@:1
```
2. **Incrustare sempre la connessione VNC in un tunnel SSH** da parte degli amministratori e bloccare le porte `5900-5910/tcp` sul firewall (`ufw deny 5900:5910/tcp`):
```bash
ssh -L 5901:127.0.0.1:5901 utente@<IP_TARGET>
```

## Come verificare che sia corretto
```bash
ss -tulpn | grep :590
nmap -p 5900-5905 --script vnc-info <IP_TARGET>
```
*Output atteso DOPO la correzione:* `127.0.0.1:5901` in ascolto locale e porte `5900-5905` chiuse/filtrate dalla rete esterna.

## Cosa può rompersi
- Client VNC legacy (es. vecchie versioni di TightVNC o viewer privi di supporto `VeNCrypt` / TLS) che tentano di collegarsi direttamente all'IP del server sulla porta `5900` senza aprire prima un tunnel SSH perderanno l'accesso grafico.

## Fonti
* [TigerVNC Documentation - vncpasswd and SecurityTypes Manual](https://tigervnc.org/doc/vncpasswd.html)
* [IETF RFC 6143 - The Remote Framebuffer Protocol (VNC Security Types)](https://datatracker.ietf.org/doc/html/rfc6143)
