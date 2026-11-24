# R26 - LDAP: bind anonimo o firma LDAP non obbligatoria

## Cos'è e perché è un rischio
Consentire operazioni **LDAP Anonymous Bind** (interrogazioni senza credenziali sulla porta TCP `389`) o non imporre la **firma LDAP (LDAP Signing)** e il **Channel Binding (LDAPS TCP `636`)** espone l'intera directory aziendale:
- **Enumerazione completa di Active Directory / OpenLDAP:** un utente non autenticato sulla rete può estrarre utenti, gruppi amministrativi (`Domain Admins`), policy password, descrizioni (spesso contenenti password in chiaro) e struttura organizzativa.
- **Attacchi LDAP Relay (NTLM-to-LDAP):** senza LDAP Signing e Channel Binding obbligatori, un attaccante che intercetta un'autenticazione NTLM può inoltrarla al Domain Controller via LDAP per creare account privilegiati o modificare i diritti RBCD.

## Come verificare il problema
```bash
ldapsearch -x -H ldap://<IP_TARGET> -b "dc=azienda,dc=local" "(objectClass=user)" sAMAccountName
```
*Output atteso PRIMA della correzione (se vulnerabile):* elenco completo degli oggetti utente restituito senza fornire username né password (`result: 0 Success`).

## Come rimediare (Remediation)

1. **In Active Directory (Windows Server GPO):** imporre la firma LDAP obbligatoria tramite Group Policy (*Default Domain Controllers Policy*):
   - *Computer Configuration* -> *Policies* -> *Windows Settings* -> *Security Settings* -> *Local Policies* -> *Security Options* -> **Domain controller: LDAP server signing requirements** = **Require signing**.
   - Impostare inoltre **Domain controller: LDAP server channel binding token requirements** = **Always** e configurare un certificato server valido per abilitare **LDAPS (porta TCP 636)**.
2. **In OpenLDAP (`/etc/ldap/slapd.d/`):** disabilitare il bind anonimo aggiungendo `olcDisallows: bind_anon` e richiedendo autenticazione per le ricerche (`olcRequires: authc`):
```bash
cat << 'LDIF' > /tmp/disable_anon.ldif
dn: cn=config
changetype: modify
add: olcDisallows
olcDisallows: bind_anon
LDIF
ldapmodify -Y EXTERNAL -H ldapi:/// -f /tmp/disable_anon.ldif
```

## Come verificare che sia corretto
```bash
ldapsearch -x -H ldap://<IP_TARGET> -b "dc=azienda,dc=local" "(objectClass=user)"
```
*Output atteso DOPO la correzione:* `ldap_bind: Inappropriate authentication (48)` / `Operations error (1): In order to perform this operation a successful bind must be completed on the connection`.

## Cosa può rompersi
- Applicazioni legacy, stampanti multifunzione (rubrica indirizzi), firewall o appliance di rete configurati per interrogare LDAP tramite **Anonymous Bind** o su porta `389` senza firma/TLS smetteranno di autenticare o cercare utenti finché non verrà configurato un **service account LDAP dedicato a privilegi minimi** con LDAPS (`636`).
- Client Linux/Unix vecchi che usano `nss-pam-ldapd` o `sssd` senza `ldap_id_use_start_tls = true` potrebbero fallire le query verso il Domain Controller.

## Fonti
* [Microsoft Learn - Enable LDAP signing in Windows Server (ADV190023)](https://learn.microsoft.com/en-us/troubleshoot/windows-server/active-directory/enable-ldap-signing-in-windows-server)
* [OpenLDAP Software 2.6 Administrator's Guide - Disabling Anonymous Binds](https://www.openldap.org/doc/admin26/security.html#Disabling%20Anonymous%20Binds)
