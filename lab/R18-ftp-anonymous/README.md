# Lab R18 - FTP con accesso anonimo abilitato
- `vulnerabile/Dockerfile`: `vsftpd` configurato con `anonymous_enable=YES` che espone `/var/ftp/segreto.txt`.
- `corretto/Dockerfile`: `vsftpd` configurato con `anonymous_enable=NO`.
- `verifica.sh`: verifica tramite `curl ftp://target/` (`exit 1` se anonimo/inattivo, `0` se rifiutato con 530).
