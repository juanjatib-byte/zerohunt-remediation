# R24 - NTP con comandi di monitoraggio (mode 6 / monlist)

## Cos'è e perché è un rischio
I server **NTP (Network Time Protocol, porta UDP 123)** con i comandi di controllo e monitoraggio **Mode 6 (`ntpq`)** o **Mode 7 (`monlist` / `ntpdc`)** abilitati verso l'esterno espongono informazioni sensibili e fungono da amplificatori DDoS:
- **Attacchi DDoS NTP Amplification (CVE-2013-5211):** una singola richiesta `monlist` di pochi byte restituisce l'elenco degli ultimi 600 client sincronizzati con il server (fattore di amplificazione fino a 556x), saturando la rete e causando il blacklisting dell'IP aziendale.
- **Information Disclosure (Mode 6):** tramite `ntpq -c rv` o `ntpq -c peers` un attaccante può enumerare versione esatta del demone `ntpd`, sistema operativo, architettura e indirizzi IP interni dei server upstream/downstream.

## Come verificare il problema
```bash
ntpq -c rv <IP_TARGET>
nmap -sU -p 123 --script ntp-monlist,ntp-info <IP_TARGET>
```
*Output atteso PRIMA della correzione (se vulnerabile):* `ntpq` restituisce le variabili di stato del server (`version="ntpd 4.2..."`, `processor=...`) oppure `ntp-monlist` elenca gli host client recenti.

## Come rimediare (Remediation)

1. **In `ntpd` (`/etc/ntp.conf`):** disabilitare esplicitamente `monlist` (`disable monitor`) e bloccare le query di controllo Mode 6/7 (`noquery`, `nomodify`, `notrap`) nelle direttive `restrict` di default, consentendole solo da `127.0.0.1`:
```bash
cat << 'CONF' >> /etc/ntp.conf
disable monitor
restrict default kod nomodify notrap nopeer noquery
restrict -6 default kod nomodify notrap nopeer noquery
restrict 127.0.0.1
restrict ::1
CONF
systemctl restart ntp
```
2. **In `chrony` (`/etc/chrony/chrony.conf`):** assicurarsi che `cmdallow` sia limitato a `127.0.0.1` / `::1` (impostazione predefinita) e bloccare la porta `UDP 123` in ingresso sul firewall perimetrale se il server non deve fornire sincronizzazione oraria pubblica.

## Come verificare che sia corretto
```bash
ntpq -c rv <IP_TARGET>
```
*Output atteso DOPO la correzione:* `<IP_TARGET>: timed out, nothing received` (`***Request timed out`).

## Cosa può rompersi
- Strumenti di monitoraggio centralizzato (Nagios, Zabbix, Prometheus) che interrogano lo stato di sincronizzazione NTP da un server remoto tramite `ntpq` riceveranno timeout finché l'IP del server di monitoraggio non verrà aggiunto esplicitamente con `restrict <IP_MONITORING> nomodify notrap nopeer`.
- Vecchi script di diagnostica `ntpdc` non potranno più interrogare remotamente il demone NTP.

## Fonti
* [NTP.org Official Documentation - Miscellaneous Options (disable monitor / restrict)](https://docs.ntp.org/ntp4/release/miscopt.html#noquery)
* [CISA Alert TA14-013A - NTP Amplification Attacks Using monlist](https://www.cisa.gov/news-events/alerts/2014/01/13/ntp-amplification-attacks)
