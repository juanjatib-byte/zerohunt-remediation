# R10 - SSH con login root e password abilitati

## Cos'è e perché è un rischio
Consentire l'accesso diretto dell'utente amministrativo **`root`** tramite **SSH (porta TCP 22)** e mantenere abilitata l'autenticazione tramite **password** (`PermitRootLogin yes` e `PasswordAuthentication yes`) espone il server a rischi elevati:
- **Attacchi brute-force e credential stuffing:** l'account `root` esiste su ogni sistema Linux/Unix, quindi gli attaccanti conoscono già lo username e devono indovinare soltanto la password.
- **Assenza di tracciabilità individuale:** se più amministratori accedono direttamente come `root`, nei log di sistema (`/var/log/auth.log`) non è possibile distinguere chi ha eseguito un'azione.
- **Compromissione totale immediata:** in caso di password debole o trafugata, l'attaccante ottiene immediatamente i massimi privilegi di sistema senza dover effettuare privilege escalation.

## Come verificare il problema

### Dalla rete
Tentare una connessione SSH verso l'utente `root` verificando i metodi di autenticazione offerti dal server:
```bash
ssh -o PreferredAuthentications=none -o StrictHostKeyChecking=no root@<IP_TARGET>
```
*Output atteso PRIMA della correzione (se vulnerabile):*
```text
root@<IP_TARGET>: Permission denied (publickey,password).
```

### Sul server Linux
Verificare la configurazione attiva di OpenSSH:
```bash
sshd -T | grep -E "permitrootlogin|passwordauthentication"
```
*Output atteso PRIMA della correzione:*
```text
permitrootlogin yes
passwordauthentication yes
```

## Come rimediare (Remediation)

1. Configurare prima l'accesso tramite **chiave pubblica SSH** (`~/.ssh/authorized_keys`) per un utente amministrativo non-root appartenente al gruppo `sudo` / `wheel`.
2. Modificare `/etc/ssh/sshd_config` disabilitando sia il login diretto di `root` sia l'autenticazione tramite password:
   ```text
   PermitRootLogin no
   PasswordAuthentication no
   PubkeyAuthentication yes
   ChallengeResponseAuthentication no
   ```
3. Verificare la sintassi e riavviare il servizio SSH:
   ```bash
   sshd -t && systemctl restart sshd
   ```

## Come verificare che sia corretto

### Dalla rete
```bash
ssh -o PreferredAuthentications=none -o StrictHostKeyChecking=no root@<IP_TARGET>
```
*Output atteso DOPO la correzione:*
```text
root@<IP_TARGET>: Permission denied (publickey).
```

### Sul server Linux
```bash
sshd -T | grep -E "permitrootlogin|passwordauthentication"
```
*Output atteso DOPO la correzione:*
```text
permitrootlogin no
passwordauthentication no
```

## Cosa può rompersi
- **Lockout amministrativo:** se si disabilita `PasswordAuthentication` prima di aver copiato e testato la chiave pubblica SSH (`ssh-copy-id`) su un utente non-root con privilegi `sudo`, si rischia di rimanere bloccati fuori dal server.
- **Script e automazioni legacy:** strumenti di backup (es. `rsync`/`scp` via cron) o tool di deployment che usano `sshpass` o login diretto come `root` smetteranno di funzionare.

## Fonti
* [CIS Distribution Independent Linux Benchmark - Ensure SSH root login is disabled](https://cisecurity.org)
* [OpenSSH Manual - sshd_config(5)](https://openbsd.org)
