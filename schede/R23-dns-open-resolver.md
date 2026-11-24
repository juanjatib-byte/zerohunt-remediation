# R23 - DNS: resolver aperto verso Internet

## Cos'è e perché è un rischio
Un server **DNS (porta UDP/TCP 53)** configurato per accettare query ricorsive da qualsiasi indirizzo IP (`recursion yes; allow-recursion { any; };`) funziona come **Open DNS Resolver**, esponendo l'infrastruttura a gravi abusi:
- **Attacchi DDoS DNS Amplification / Reflection:** gli attaccanti inviano richieste DNS con IP sorgente falsificato (spoofed) verso il resolver aperto, che risponde con pacchetti fino a 50 volte più grandi verso la vittima, saturando la banda aziendale e causando blacklisting dell'IP pubblico.
- **DNS Cache Poisoning:** un attaccante esterno può tentare di avvelenare la cache del resolver con record malevoli, dirottando gli utenti interni verso siti di phishing.
- **Esaurimento delle risorse (DoS):** query ricorsive continue dall'esterno saturano CPU, memoria e socket del server DNS.

## Come verificare il problema
```bash
dig @<IP_PUBBLICO_DNS> example.com A +short
```
*Output atteso PRIMA della correzione (se vulnerabile):* restituisce l'indirizzo IP risolto per domini esterni (`93.184.216.34`) anziché rifiutare la ricorsione (`REFUSED`).

## Come rimediare (Remediation)

1. **In BIND9 (`/etc/bind/named.conf.options`):** limitare `allow-recursion` e `allow-query-cache` esclusivamente a `localhost` e alle subnet interne fidate (oppure disabilitare del tutto `recursion no;` sui server DNS autoritativi esposti su Internet):
```bash
cat << 'CONF' > /etc/bind/named.conf.options
options {
    directory "/var/cache/bind";
    recursion yes;
    allow-recursion { 127.0.0.1; 10.0.0.0/8; 192.168.0.0/16; };
    allow-query-cache { 127.0.0.1; 10.0.0.0/8; 192.168.0.0/16; };
};
CONF
named-checkconf && systemctl reload named
```
2. **In Windows Server DNS:** aprire `dnsmgmt.msc` -> *Proprietà server* -> scheda *Avanzate* -> selezionare **Disabilita ricorsione (disabilita anche server d'inoltro)** sui server autoritativi pubblici.

## Come verificare che sia corretto
```bash
dig @<IP_PUBBLICO_DNS> example.com A
```
*Output atteso DOPO la correzione:* `status: REFUSED` (con flag `ra` non disponibile per client esterni).

## Cosa può rompersi
- Sedi remote, filiali o client VPN che utilizzano l'IP pubblico del server DNS aziendale come resolver primario senza passare dal tunnel VPN interno non potranno più risolvere domini Internet finché non verranno riconfigurati per usare il DNS interno tramite VPN.
- Eventuali record DNS esterni inseriti nella cache o query di inoltro provenienti da server DMZ non inclusi nell'ACL `allow-recursion` riceveranno `REFUSED`.

## Fonti
* [BIND 9 Documentation - allow-recursion and allow-query-cache](https://bind9.readthedocs.io/en/latest/reference.html#namedconf-statement-allow-recursion)
* [CISA Alert TA13-088A - DNS Amplification Attacks](https://www.cisa.gov/news-events/alerts/2013/03/29/dns-amplification-attacks)
