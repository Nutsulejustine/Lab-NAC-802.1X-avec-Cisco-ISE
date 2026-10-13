# Configuration de Cisco ISE 2.7

Configuration faite dans l'interface web d'ISE (`https://192.168.10.30/admin`), dans cet ordre.

## 1. Paramètres réseau du nœud (CLI)

DNS et NTP doivent pointer vers le contrôleur de domaine, sinon la jonction à l'AD échoue :

```text
configure terminal
ip name-server 192.168.10.40
ntp server 192.168.10.40
```

> Piège rencontré : le DNS `8.8.8.8` saisi à l'installation empêchait la résolution des enregistrements SRV du domaine.
> Et si l'heure de l'AD et celle d'ISE s'écartent de plus de 5 minutes, Kerberos refuse tout (`LW_ERROR_CLOCK_SKEW`).

## 2. Déclarer le switch (Network Device)

`Administration > Network Resources > Network Devices > Add`

| Champ | Valeur |
|---|---|
| Name | `Cisco-IOSvL2-1` |
| IP Address | `192.168.10.55/32` |
| Device Profile | `Cisco` |
| RADIUS Authentication Settings > Shared Secret | même valeur que `<CLE_RADIUS>` sur le switch |

## 3. Joindre le domaine Active Directory

`Administration > Identity Management > External Identity Sources > Active Directory > Add`

- Join Point Name : `LOTIE-AD`
- Domain : `lotietelecom.local`
- Onglet **Groups** : importer `lotietelecom.local/Users/Collaborateurs` et `lotietelecom.local/Users/IT`

Le point de jonction doit être à l'état **Operational**.

## 4. Downloadable ACL

`Policy > Policy Elements > Results > Authorization > Downloadable ACLs`

- Nom : `DACL-TEST-HTTP`
- Contenu : voir [`DACL-TEST-HTTP.txt`](DACL-TEST-HTTP.txt) (HTTP autorisé vers l'AD, tout le reste refusé). Liste de démonstration, pas une politique de production.

## 5. Profils d'autorisation

`Policy > Policy Elements > Results > Authorization > Authorization Profiles`

| Profil | VLAN | dACL | Attributs RADIUS produits |
|---|---|---|---|
| `AuthZ-Collaborateurs-VLAN20` | 20 | `DACL-TEST-HTTP` | `Tunnel-Private-Group-ID = 1:20`, `Tunnel-Type = 1:13`, `Tunnel-Medium-Type = 1:6` |
| `AuthZ-IT-VLAN15` | 15 | aucune | `Tunnel-Private-Group-ID = 1:15`, `Tunnel-Type = 1:13`, `Tunnel-Medium-Type = 1:6` |

## 6. Policy Set : règles d'autorisation

`Policy > Policy Sets`, source d'identités de l'authentification Dot1X : `LOTIE-AD`.

Les règles sont évaluées **de haut en bas**, la première qui correspond s'applique :

| Ordre | Règle | Conditions | Profil |
|---|---|---|---|
| 1 | `Succes-IT-VLAN15` | `Wired_802.1X` ET `LOTIE-AD-ExternalGroups Equals lotietelecom.local/Users/IT` | `AuthZ-IT-VLAN15` |
| 2 | `Succes-Collaborateurs-VLAN20` | `Wired_802.1X` ET `LOTIE-AD-ExternalGroups Equals lotietelecom.local/Users/Collaborateurs` | `AuthZ-Collaborateurs-VLAN20` |
| 3 | `Access` | `Wired_802.1X` | `PermitAccess` |

Un échec d'authentification ne passe par aucune de ces règles : ISE renvoie un `Access-Reject` et c'est le switch qui place le port en VLAN 99.

## 7. Vérifier

`Operations > RADIUS > Live Logs` : chaque tentative avec l'identité, la MAC, le switch, le port, la règle appliquée et, en cas d'échec, la raison du rejet.
