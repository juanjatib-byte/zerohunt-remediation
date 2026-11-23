# R20 — Redis esposto senza autenticazione

## Cos'è e perché è un rischio
Redis è un database in-memory che, per impostazione predefinita, non richiede alcuna password per accettare connessioni. Se il servizio è raggiungibile dalla rete senza autenticazione, qualsiasi utente o attaccante può leggere, modificare o cancellare tutti i dati in memoria, oltre a sfruttare comandi amministrativi per compromettere l'intero server ospite.

## Come correggere

### Linux (Debian/Ubuntu e RHEL)
1. Aprire il file di configurazione principale di Redis (`/etc/redis/redis.conf` su Debian/Ubuntu oppure `/etc/redis.conf` su RHEL):
```bash
sudo nano /etc/redis/redis.conf
```

2. Aggiungere o decommentare la direttiva `requirepass` impostando una password robusta (esempio usato nel laboratorio):
```conf
requirepass SuperClaveSegura2026!
```

3. Riavviare il servizio Redis per applicare la modifica:
```bash
sudo systemctl restart redis-server   # Debian/Ubuntu
sudo systemctl restart redis          # RHEL
```

## Come verificare che sia corretto

### Dalla rete
Da un'altra macchina sulla rete, interrogare il server Redis senza fornire credenziali tramite `redis-cli`:
```bash
redis-cli -h <IP_TARGET> ping
```
* **Output atteso PRIMA della correzione:**
```text
PONG
```
* **Output atteso DOPO la correzione:**
```text
NOAUTH Authentication required.
```

### Sulla macchina
Sul server locale, verificare che il parametro `requirepass` sia attivo e che il login con password funzioni:
```bash
redis-cli -a 'SuperClaveSegura2026!' ping
```
* **Output atteso dopo la correzione:**
```text
PONG
```

### Verifica in laboratorio (`lab/R20-redis/`)
Il laboratorio è disponibile nel percorso `lab/R20-redis/`.

* **Esecuzione su stato vulnerabile (`exit code: 1`):**
```text
[*] Controllo autenticazione Redis su target:6379...
[*] Risposta ricevuta: PONG
[VULNERABILE] Redis risponde senza autenticazione!
```

* **Esecuzione su stato corretto (`exit code: 0`):**
```text
[*] Controllo autenticazione Redis su target:6379...
[*] Risposta ricevuta: NOAUTH Authentication required.
[OK] Redis richiede autenticazione. Configurazione sicura.
```

## Cosa può rompersi
Tutte le applicazioni, i microservizi o gli script di monitoraggio che si collegano a questa istanza Redis senza credenziali smetteranno di funzionare, ricevendo l'errore `NOAUTH Authentication required.`. Prima di applicare la modifica in produzione, aggiornare le stringhe di connessione dei client (es. `redis://:SuperClaveSegura2026!@host:6379`) e monitorare i log applicativi per individuare eventuali servizi non aggiornati.

## Fonti
* [Redis Security Documentation — Authentication](https://redis.io/docs/latest/operate/oss_and_stack/management/security/)
* [Redis Command Reference — AUTH](https://redis.io/docs/latest/commands/auth/)
