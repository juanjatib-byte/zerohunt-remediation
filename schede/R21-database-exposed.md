# R21 - Database (MySQL / PostgreSQL) in ascolto su tutte le interfacce

## Cos'è e perché è un rischio
Configurare un server database (**MySQL/MariaDB** su porta TCP `3306` o **PostgreSQL** su porta TCP `5432`) in ascolto su `0.0.0.0` (tutte le interfacce di rete) anziché su `127.0.0.1` o su una rete backend isolata espone direttamente il motore dati:
- **Attacchi brute-force e credential stuffing:** un attaccante in rete può tentare l'accesso agli account privilegiati (`root`, `postgres`) senza passare dall'applicazione web.
- **Esfiltrazione o distruzione dei dati:** in caso di credenziali deboli o vulnerabilità del DBMS, l'attaccante può scaricare interi database (`mysqldump` / `pg_dump`) o cifrarli a scopo ransomware.
- **Sfruttamento di vulnerabilità RCE nel motore SQL:** alcuni database permettono l'esecuzione di comandi di sistema tramite UDF (User-Defined Functions) o `COPY ... FROM PROGRAM`.

## Come verificare il problema
```bash
ss -tulpn | grep -E ":(3306|5432)\b"
```
*Output atteso PRIMA della correzione (se vulnerabile):* `0.0.0.0:3306` o `*:5432` (il database accetta connessioni da qualsiasi interfaccia di rete).

## Come rimediare (Remediation)

1. **MySQL / MariaDB (`/etc/mysql/mysql.conf.d/mysqld.cnf`):** limitare `bind-address` a `127.0.0.1` (oppure all'IP della VLAN applicativa privata):
```bash
sed -i 's/^bind-address.*/bind-address = 127.0.0.1/' /etc/mysql/mysql.conf.d/mysqld.cnf
systemctl restart mysql
```
2. **PostgreSQL (`/etc/postgresql/*/main/postgresql.conf` e `pg_hba.conf`):** impostare `listen_addresses = 'localhost'` e limitare le subnet autorizzate in `pg_hba.conf`:
```bash
sed -i "s/^#*listen_addresses.*/listen_addresses = 'localhost'/" /etc/postgresql/*/main/postgresql.conf
systemctl restart postgresql
```
3. **Firewall perimetrale e host (`ufw`):** bloccare le porte `3306` e `5432` dall'esterno (`ufw deny 3306/tcp && ufw deny 5432/tcp`).

## Come verificare che sia corretto
```bash
ss -tulpn | grep -E ":(3306|5432)\b"
```
*Output atteso DOPO la correzione:* `127.0.0.1:3306` / `127.0.0.1:5432`.

## Cosa può rompersi
- Applicazioni web, microservizi o worker ospitati su **server separati** (architettura multi-tier) non riusciranno più a connettersi al database se `bind-address` viene impostato su `127.0.0.1` invece che sull'IP della VLAN backend privata con regole `pg_hba.conf` / `GRANT` ristrette.
- Strumenti di amministrazione remota (MySQL Workbench, pgAdmin, DBeaver) utilizzati dagli sviluppatori richiederanno un **tunnel SSH** per collegarsi.

## Fonti
* [MySQL 8.0 Reference Manual - bind-address System Variable](https://dev.mysql.com/doc/refman/8.0/en/server-system-variables.html#sysvar_bind_address)
* [PostgreSQL Documentation - listen_addresses Connection Settings](https://www.postgresql.org/docs/current/runtime-config-connection.html#GUC-LISTEN-ADDRESSES)
