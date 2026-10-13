#!/usr/bin/env bash
# Laisse passer les trames EAPOL (adresse 01:80:C2:00:00:03) sur le pont Linux du réseau d'accès.
# Par défaut, un pont Linux ne relaie pas les adresses 01:80:C2:00:00:0X : sans ce réglage,
# le switch ne reçoit jamais les trames 802.1X du client.
# Le réglage ne survit pas toujours à un redémarrage : relancer ce script avant chaque séance de test.
#
# Usage : ./fix-eapol-bridge.sh [nom_du_pont]   (par défaut : virbr-access)

BRIDGE="${1:-virbr-access}"
MASK_FILE="/sys/class/net/${BRIDGE}/bridge/group_fwd_mask"

if [[ ! -e "$MASK_FILE" ]]; then
    echo "Pont ${BRIDGE} introuvable. Le réseau accessnet est-il démarré ? (sudo virsh net-start accessnet)" >&2
    exit 1
fi

# bit 3 du masque = 8 -> adresse 01:80:C2:00:00:03 (PAE, EAPOL)
echo 8 | sudo tee "$MASK_FILE" > /dev/null
echo "group_fwd_mask de ${BRIDGE} = $(cat "$MASK_FILE")"
