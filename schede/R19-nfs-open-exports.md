# R19 - NFS export aperti senza restrizioni IP

## Cos'è e perché è un rischio
Configurare condivisioni **NFS (Network File System, porta TCP/UDP 2049 e rpcbind 111)** nel file `/etc/exports` utilizzando il wildcard `*` (es. `/srv/nfs *(rw,sync,no_root_squash)`) consente a qualsiasi host sulla rete di montare il filesystem remoto:
- **Accesso non autorizzato a file riservati:** qualunque macchina nella rete può eseguire `mount -t nfs <IP_TARGET>:/srv/nfs /mnt` e leggere dati sensibili.
- **Escalation a root (se presente `no_root_squash`):** un utente `root` su una macchina client non fidata può creare file eseguibili con bit SUID o sovrascrivere chiavi SSH sull'export montato.
- **Enumerazione semplice dalla rete:** tramite `showmount -e <IP_TARGET>` un attaccante scopre immediatamente tutti gli export esposti a `*` (`everyone`).

## Come verificare il problema
```bash
showmount -e <IP_TARGET>
```
*Output atteso PRIMA della correzione (se vulnerabile):*
```text
Export list for <IP_TARGET>:
/srv/nfs *
```
*(Il simbolo `*` indica che la directory è esportata verso qualsiasi indirizzo IP senza restrizioni).*

## Come rimediare (Remediation)

1. **Limitare gli export in `/etc/exports`** sostituendo il wildcard `*` con gli indirizzi IP o le subnet autorizzate, impostando `root_squash` (predefinito) e `ro` dove non è richiesta la scrittura:
```bash
cat << 'CONF' > /etc/exports
/srv/nfs 10.10.20.0/24(ro,sync,root_squash,no_subtree_check)
CONF
exportfs -ra
systemctl restart nfs-kernel-server
```
2. **Bloccare le porte NFS/RPC (`111`, `2049`) sul firewall** dalle reti non autorizzate (`ufw allow from 10.10.20.0/24 to any port 2049 proto tcp`).

## Come verificare che sia corretto
```bash
showmount -e <IP_TARGET>
```
*Output atteso DOPO la correzione:* `/srv/nfs 10.10.20.0/24` (nessun wildcard `*` presente nell'elenco degli export).

## Cosa può rompersi
- Client Linux/Unix, container o nodi di cluster che montano la condivisione NFS da indirizzi IP fuori dalla subnet autorizzata (o tramite NAT dinamico) riceveranno `mount.nfs: access denied by server while mounting`.
- Applicazioni che scrivono file direttamente come utente `root` remoto smetteranno di avere privilegi di superutente sull'export a causa dell'attivazione di `root_squash`.

## Fonti
* [Ubuntu Server Documentation - Network File System (NFS)](PLACEHOLDER_UBU_NFS)
* [Linux Manpage - exports(5) (/etc/exports)](PLACEHOLDER_MAN_EXPORTS)
* [CIS Distribution Independent Linux Benchmark](PLACEHOLDER_CIS)
