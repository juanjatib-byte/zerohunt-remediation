# ZeroHunt Remediation — Catalogo di Hardening & Lab Docker (R01–R30)

Repository tecnico contenente **30 schede di remediation** (`schede/R01`–`R30`) per vulnerabilità infrastrutturali e di rete comuni, accompagnate da **15 laboratori Docker isolati e riproducibili** (`lab/`) per verificare sia lo stato vulnerabile sia l'efficacia della correzione.

## Struttura del repository

- `indice.csv`: catalogo completo delle 30 vulnerabilità con codice, titolo, gravità, piattaforme interessate e disponibilità del laboratorio Docker (`verificata_in_lab`).
- `schede/`: 30 guide operative strutturate con:
  1. Descrizione tecnica e impatto sulla sicurezza (*Cos'è e perché è un rischio*)
  2. Comandi di diagnostica (*Come verificare il problema*)
  3. Passaggi di hardening copiabili (*Come rimediare*)
  4. Verifica post-intervento (*Come verificare che sia corretto*)
  5. Analisi degli impatti operativi (*Cosa può rompersi*)
  6. Riferimenti a documentazione primaria (*Fonti*)
- `lab/`: 15 ambienti containerizzati basati su **Docker Compose** con profili `vulnerabile` e `corretto` e script automatizzato `verifica.sh`.

## Utilizzo dei laboratori Docker

Tutti i laboratori operano esclusivamente su reti interne isolate (`lab_net`) senza esporre porte sull'host locale.

```bash
cd lab/<NOME_LAB>

# 1. Test stato vulnerabile (atteso: [VULNERABILE], exit 1)
docker compose --profile vulnerabile up -d --build
./verifica.sh
docker compose --profile vulnerabile down

# 2. Test stato corretto (atteso: [OK], exit 0)
docker compose --profile corretto up -d --build
./verifica.sh
docker compose --profile corretto down
```
