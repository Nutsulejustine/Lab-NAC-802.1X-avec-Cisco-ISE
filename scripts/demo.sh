#!/usr/bin/env bash
# Démo de soutenance sans rien taper en direct (à lancer en root sur le client Debian).
#   ./demo.sh ok      -> employe1, bon mot de passe   : VLAN 20 attendu
#   ./demo.sh ko      -> mot de passe faux            : VLAN 99 attendu
#   ./demo.sh it      -> it1 (groupe IT)              : VLAN 15 attendu
#   ./demo.sh status  -> état actuel du Supplicant
#   ./demo.sh stop    -> arrête wpa_supplicant
# Vérifier ensuite côté switch : show authentication sessions interface Gi0/1 details

IFACE="ens1"
DIR="/etc/wpa_supplicant"
LOG="/var/log/wpa.log"

status() {
    wpa_cli -i "$IFACE" status 2>/dev/null | grep -E 'Supplicant PAE state|suppPortStatus|EAP state|selectedMethod' \
        || echo "wpa_supplicant ne tourne pas sur ${IFACE}"
}

stop() {
    pkill -f "wpa_supplicant -i ${IFACE}" 2>/dev/null
    sleep 1
}

run() {
    local conf="$DIR/$1"
    [[ -f "$conf" ]] || { echo "Profil introuvable : $conf" >&2; exit 1; }
    stop
    echo ">>> Authentification avec $(basename "$conf")"
    wpa_supplicant -i "$IFACE" -c "$conf" -D wired -B -f "$LOG"
    sleep 8
    status
    grep -E 'EAP-SUCCESS|EAP-FAILURE|error 691' "$LOG" | tail -n 3
}

case "$1" in
    ok)     run wired.conf ;;
    ko)     run mauvais.conf ;;
    it)     run it1.conf ;;
    status) status ;;
    stop)   stop; echo "wpa_supplicant arrêté" ;;
    *)      echo "Usage : $0 {ok|ko|it|status|stop}"; exit 1 ;;
esac
