# R09 - SSH con algoritmi deboli (CBC, SHA-1, diffie-hellman-group1)

## Cos'è e perché è un rischio
Il servizio **SSH (porta TCP 22)** utilizza algoritmi crittografici per lo scambio delle chiavi (**KEX**), la cifratura simmetrica (**Ciphers**) e l'integrità dei messaggi (**MAC**). L'abilitazione di algoritmi obsoleti espone le sessioni amministrative a diversi attacchi:
- **Cifrari in modalità CBC** (es. `aes128-cbc`, `3des-cbc`): vulnerabili ad attacchi di tipo *plaintext recovery* (CVE-2008-5161).
- **MAC basati su SHA-1 / MD5** (es. `hmac-sha1`, `hmac-md5`): soggetti ad attacchi di collisione crittografica.
- **Key Exchange deboli** (es. `diffie-hellman-group1-sha1`, `diffie-hellman-group14-sha1`): utilizzano gruppi Diffie-Hellman a 1024/2048 bit ormai deprecati e vulnerabili ad attacchi di pre-computazione (*Logjam*).

## Come verificare il problema

### Dalla rete
Utilizzare `nmap` da una macchina Linux per enumerare gli algoritmi negoziati dal server SSH:
```bash
nmap -p 22 --script ssh2-enum-algos <IP_TARGET>
```
*Output atteso PRIMA della correzione (se vulnerabile):*
```text
| ssh2-enum-algos:
|   kex_algorithms:
|     diffie-hellman-group1-sha1
|   encryption_algorithms:
|     aes128-cbc
|     3des-cbc
|   mac_algorithms:
|     hmac-sha1
```

### Sul server Linux
Verificare la configurazione effettiva caricata dal demone OpenSSH:
```bash
sshd -T | grep -E "kexalgorithms|ciphers|macs"
```

## Come rimediare (Remediation)

1. Modificare il file `/etc/ssh/sshd_config` imponendo esclusivamente algoritmi moderni e sicuri (curve ellittiche e cifrari AEAD):
   ```text
   KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512
   Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com
   MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com
   ```
2. Verificare la sintassi della configurazione e riavviare il servizio:
   ```bash
   sshd -t && systemctl restart sshd
   ```

## Come verificare che sia corretto

### Dalla rete
Rieseguire la scansione con `nmap` oppure tentare una connessione forzando esplicitamente un algoritmo obsoleto:
```bash
ssh -oKexAlgorithms=+diffie-hellman-group1-sha1 -oCiphers=+aes128-cbc user@<IP_TARGET>
```
*Output atteso DOPO la correzione:*
```text
Unable to negotiate with <IP_TARGET> port 22: no matching key exchange method found.
```

### Sul server Linux
```bash
sshd -T | grep -E "kexalgorithms|ciphers|macs"
```
*Output atteso DOPO la correzione:* compaiono solo algoritmi `curve25519`, `aes*-gcm`, `chacha20-poly1305` e `hmac-sha2-*-etm`.

## Cosa può rompersi
Client SSH molto datati (es. vecchi switch/router di rete con firmware obsoleti, sistemi Linux/Unix legacy o vecchie librerie Paramiko/JSch non aggiornate) che non supportano `curve25519` o cifrari `GCM`/`ChaCha20` non riusciranno più a connettersi al server finché non verranno aggiornati o gestiti tramite un bastion host dedicato.

## Fonti
* [Mozilla Infosec Guidelines - OpenSSH](https://mozilla.org)
* [CIS Distribution Independent Linux Benchmark - SSH Server Configuration](https://cisecurity.org)
