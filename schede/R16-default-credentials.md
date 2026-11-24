# R16 - Credenziali di default su pannelli e dispositivi

## Cos'è e perché è un rischio
Lasciare attive **credenziali predefinite di fabbrica** (es. `admin:admin`, `admin:password`, `root:root`, `admin:1234`) su interfacce web di gestione, router, switch, firewall, telecamere IP o console applicative rappresenta una vulnerabilità critica:
- **Accesso amministrativo immediato senza exploit:** gli elenchi delle credenziali di default sono pubblici e integrati negli scanner automatici (es. Nmap NSE `http-default-accounts`).
- **Compromissione completa dell'infrastruttura:** un attaccante può riconfigurare regole firewall, intercettare traffico o muoversi lateralmente verso altri sistemi.
- **Assenza di tracciabilità individuale:** un account condiviso `admin` impedisce di risalire all'amministratore che ha eseguito una modifica.

## Come verificare il problema
```bash
curl -s -o /dev/null -w "%{http_code}\n" -u admin:admin http://<IP_TARGET>/admin/
```
*Output atteso PRIMA della correzione (se vulnerabile):* `200` (il server accetta `admin:admin` e concede l'accesso al pannello).

## Come rimediare (Remediation)

1. **Sostituire immediatamente tutte le credenziali di default** al primo avvio con password lunghe e univoche (almeno 14-16 caratteri, generate da password manager) o autenticare gli operatori tramite **SSO / LDAP / RADIUS** con account nominativi.
2. **Rigenerare il file delle credenziali HTTP Basic Auth (es. Nginx )** con hash moderno () rimuovendo :
   ```bash
   htpasswd -c -B /etc/nginx/.htpasswd operatore_admin
   chmod 640 /etc/nginx/.htpasswd
   chown root:www-data /etc/nginx/.htpasswd
   nginx -t && systemctl reload nginx
   ```
3. **Disabilitare o rinominare l'account  predefinito** dove il dispositivo lo consente e attivare il blocco temporaneo dopo tentativi falliti (rate-limiting / fail2ban).

## Come verificare che sia corretto
```bash
curl -s -o /dev/null -w "%{http_code}\n" -u admin:admin http://<IP_TARGET>/admin/
```
*Output atteso DOPO la correzione:*  ().

## Cosa può rompersi
- Script di provisioning, backup o monitoraggio automatizzati (es. check HTTP con credenziali  hardcoded) smetteranno di autenticarsi finché non verranno aggiornati con un account dedicato a privilegi minimi (read-only).
- Gli operatori abituati ad accedere con le credenziali condivise di fabbrica dovranno utilizzare i propri account nominativi.

## Fonti
* [OWASP Authentication Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html)
* [NIST SP 800-63B - Digital Identity Guidelines](https://pages.nist.gov/800-63-4/sp800-63b.html)
* [Nginx Documentation - ngx_http_auth_basic_module](https://nginx.org/en/docs/http/ngx_http_auth_basic_module.html)
