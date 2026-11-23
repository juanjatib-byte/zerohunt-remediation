
# R12 — TLS 1.0 / 1.1 abilitati

## Cos'è e perché è un rischio
TLS 1.0 e TLS 1.1 sono versioni obsolete del protocollo crittografico TLS (deprecate ufficialmente dalla RFC 8996) affette da note vulnerabilità come BEAST e POODLE. Se un server accetta ancora connessioni con questi protocolli, un attaccante in posizione Man-in-the-Middle può forzare il downgrade della cifratura e decifrare o alterare il traffico sensibile.

## Come correggere

### Linux — Nginx
1. Aprire il file di configurazione del virtual host o del blocco http (es. /etc/nginx/nginx.conf o /etc/nginx/sites-available/default) e limitare ssl_protocols esclusivamente a TLS 1.2 e TLS 1.3:

    ssl_protocols TLSv1.2 TLSv1.3;

2. Verificare la sintassi e ricaricare Nginx:

    sudo nginx -t && sudo systemctl reload nginx

### Linux — Apache HTTP Server
1. Aprire la configurazione SSL (/etc/apache2/mods-available/ssl.conf su Debian/Ubuntu oppure /etc/httpd/conf.d/ssl.conf su RHEL) e disabilitare TLS 1.0 e TLS 1.1:

    SSLProtocol -all +TLSv1.2 +TLSv1.3

2. Verificare la sintassi e riavviare Apache:

    sudo apachectl configtest && sudo systemctl restart apache2
    sudo apachectl configtest && sudo systemctl restart httpd

### Windows Server (IIS / SChannel)
1. Disabilitare TLS 1.0 e TLS 1.1 a livello di sistema operativo tramite PowerShell modificando le chiavi del registro SChannel:

    New-Item "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Server" -Force | Out-Null
    New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Server" -Name "Enabled" -Value 0 -PropertyType "DWord" -Force | Out-Null
    New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Server" -Name "DisabledByDefault" -Value 1 -PropertyType "DWord" -Force | Out-Null

    New-Item "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server" -Force | Out-Null
    New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server" -Name "Enabled" -Value 0 -PropertyType "DWord" -Force | Out-Null
    New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server" -Name "DisabledByDefault" -Value 1 -PropertyType "DWord" -Force | Out-Null

2. Riavviare il server per rendere effettive le modifiche al registro.

## Come verificare che sia corretto

### Dalla rete
Da un'altra macchina sulla rete, tentare una connessione forzando TLS 1.1 con openssl s_client:

    echo "Q" | openssl s_client -connect <IP_TARGET>:443 -tls1_1

* Output atteso PRIMA della correzione:
  -----BEGIN CERTIFICATE-----
  ...
  Protocol  : TLSv1.1

* Output atteso DOPO la correzione:
  error:0A00042E:SSL routines:ssl3_read_bytes:tlsv1 alert protocol version
  no peer certificate available

### Sulla macchina
* Nginx / Apache: verificare che nei file di configurazione sia presente solo TLSv1.2 e TLSv1.3:
  grep -rn "ssl_protocols\|SSLProtocol" /etc/nginx/ /etc/apache2/ /etc/httpd/ 2>/dev/null
* Windows Server: verificare via PowerShell che Enabled sia impostato a 0 sotto le chiavi TLS 1.0\Server e TLS 1.1\Server.

### Verifica in laboratorio (lab/R12-tls/)
Il laboratorio è disponibile nel percorso lab/R12-tls/.

* Esecuzione su stato vulnerabile (exit code: 1):
  [*] Controllo supporto TLS 1.1 su target:443...
  [VULNERABILE] Il server accetta connessioni con TLS 1.1!

* Esecuzione su stato corretto (exit code: 0):
  [*] Controllo supporto TLS 1.1 su target:443...
  [OK] TLS 1.1 rifiutato dal server. Configurazione sicura.

## Cosa può rompersi
Client molto vecchi (es. Windows 7 / Server 2008 R2 senza aggiornamenti, Internet Explorer 10 o precedenti, vecchi terminali POS, stampanti di rete o librerie Java 7 / Python 2.7 non aggiornate) che non supportano TLS 1.2 non riusciranno più a stabilire connessioni HTTPS e riceveranno errori di handshake SSL/TLS. Verificare i log di accesso e TLS prima di applicare la modifica in produzione.

## Fonti
* [Nginx Documentation — Module ngx_http_ssl_module (ssl_protocols)](https://nginx.org/en/docs/http/ngx_http_ssl_module.html#ssl_protocols)
* [Apache HTTP Server 2.4 Documentation — mod_ssl (SSLProtocol)](https://httpd.apache.org/docs/2.4/mod/mod_ssl.html#sslprotocol)
* [Microsoft Learn — Transport Layer Security (TLS) registry settings](https://learn.microsoft.com/en-us/windows-server/security/tls/tls-registry-settings)
* [IETF RFC 8996 — Deprecating TLS 1.0 and TLS 1.1](https://datatracker.ietf.org/doc/html/rfc8996)

