# Lab R19 - NFS export aperti senza restrizioni IP
- `vulnerabile/Dockerfile`: server NFS (`unfs3`) con export `/srv/nfs 0.0.0.0/0(rw,no_root_squash)`.
- `corretto/Dockerfile`: server NFS (`unfs3`) con export ristretto a `10.250.250.0/24` e `Root_Squash`.
- `verifica.sh`: verifica tramite `showmount -e target` (`exit 1` se aperto/inattivo, `0` se ristretto).
