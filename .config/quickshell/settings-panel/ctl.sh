#!/usr/bin/env bash
set -u

cmd="${1:-}"
shift || true

hypridle_conf="${HOME}/.config/hypr/hypridle.conf"
timeout_file="${HOME}/.config/hypr/screen-timeout"

emit() { printf '%s\n' "$*"; }

case "${cmd}" in
  wifi-radio)
    if nmcli -t -f WIFI general >/dev/null 2>&1; then
      val="$(nmcli -t -f WIFI general 2>/dev/null | head -n1)"
      if [[ "${val}" == "enabled" ]]; then emit "on"; else emit "off"; fi
    else
      emit "off"
    fi
    ;;
  wifi-radio-set)
    nmcli radio wifi "${1:-off}" >/dev/null 2>&1 || true
    ;;
  wifi-list)
    nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY device wifi list 2>/dev/null | awk -F: '
      $2 != "" {
        used = ($1 == "*") ? "1" : "0"
        gsub(/\\:/, ":", $2)
        print used "|" $2 "|" $3 "|" $4
      }
    ' | awk -F'|' '!seen[$2]++'
    ;;
  wifi-connect)
    ssid="${1:-}"
    pass="${2:-}"
    [[ -n "${ssid}" ]] || exit 1
    if [[ -n "${pass}" ]]; then
      nmcli device wifi connect "${ssid}" password "${pass}" >/dev/null 2>&1 || true
    else
      nmcli device wifi connect "${ssid}" >/dev/null 2>&1 || true
    fi
    ;;
  wifi-disconnect)
    dev="$(nmcli -t -f DEVICE,TYPE device status 2>/dev/null | awk -F: '$2=="wifi"{print $1; exit}')"
    [[ -n "${dev}" ]] && nmcli device disconnect "${dev}" >/dev/null 2>&1 || true
    ;;
  ethernet)
    nmcli -t -f DEVICE,TYPE,STATE device status 2>/dev/null \
      | awk -F: '$2=="ethernet"{print $1 "|" $3; exit}'
    ;;
  airplane)
    wifi="$(nmcli -t -f WIFI general 2>/dev/null | head -n1 || true)"
    bt="no"
    if command -v bluetoothctl >/dev/null; then
      bt="$(bluetoothctl show 2>/dev/null | awk '/Powered:/{print $2; exit}')"
    fi
    if [[ "${wifi}" == "enabled" || "${bt}" == "yes" ]]; then
      emit "off"
    else
      emit "on"
    fi
    ;;
  airplane-set)
    if [[ "${1:-}" == "on" ]]; then
      nmcli radio wifi off >/dev/null 2>&1 || true
      command -v bluetoothctl >/dev/null && bluetoothctl power off >/dev/null 2>&1 || true
    else
      nmcli radio wifi on >/dev/null 2>&1 || true
      command -v bluetoothctl >/dev/null && bluetoothctl power on >/dev/null 2>&1 || true
    fi
    ;;
  brightness)
    if command -v brightnessctl >/dev/null; then
      brightnessctl -m 2>/dev/null | awk -F, '{gsub(/%/, "", $4); print $4}'
    fi
    ;;
  brightness-set)
    brightnessctl set "${1:-50}%" >/dev/null 2>&1 || true
    ;;
  monitors)
    if command -v hyprctl >/dev/null && command -v jq >/dev/null; then
      hyprctl monitors -j 2>/dev/null | jq -r '
        .[] | [
          .name,
          ((.width|tostring) + "x" + (.height|tostring)),
          (.refreshRate|tostring),
          (.scale|tostring),
          ((.availableModes // []) | join(","))
        ] | join("|")
      '
    fi
    ;;
  monitor-set)
    name="${1:-}"
    mode="${2:-preferred}"
    scale="${3:-1}"
    [[ -n "${name}" ]] || exit 1
    hyprctl keyword monitor "${name},${mode},auto,${scale}" >/dev/null 2>&1 || true
    ;;
  volume)
    if command -v wpctl >/dev/null; then
      wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{printf "%d\n", ($2+0)*100}'
    fi
    ;;
  volume-set)
    wpctl set-volume @DEFAULT_AUDIO_SINK@ "${1:-50}%" >/dev/null 2>&1 || true
    ;;
  sinks)
    if command -v pactl >/dev/null; then
      pactl get-default-sink 2>/dev/null | awk '{print "default|" $0}'
      pactl list short sinks 2>/dev/null | awk '{print "sink|" $2}'
    fi
    ;;
  sink-set)
    pactl set-default-sink "${1:-}" >/dev/null 2>&1 || true
    ;;
  sources)
    if command -v pactl >/dev/null; then
      pactl get-default-source 2>/dev/null | awk '{print "default|" $0}'
      pactl list short sources 2>/dev/null | awk '$2 !~ /\.monitor$/{print "source|" $2}'
    fi
    ;;
  source-set)
    pactl set-default-source "${1:-}" >/dev/null 2>&1 || true
    ;;
  bt-power)
    if command -v bluetoothctl >/dev/null; then
      bluetoothctl show 2>/dev/null | awk '/Powered:/{print $2; exit}'
    else
      emit "no"
    fi
    ;;
  bt-power-set)
    bluetoothctl power "${1:-off}" >/dev/null 2>&1 || true
    ;;
  bt-devices)
    if command -v bluetoothctl >/dev/null; then
      bluetoothctl devices 2>/dev/null | awk '{mac=$2; $1=$2=""; sub(/^  /,""); print mac "|" $0}'
    fi
    ;;
  bt-scan)
    if command -v bluetoothctl >/dev/null; then
      bluetoothctl --timeout 8 scan on >/dev/null 2>&1 || true
      bluetoothctl devices 2>/dev/null | awk '{mac=$2; $1=$2=""; sub(/^  /,""); print mac "|" $0}'
    fi
    ;;
  bt-connect)
    bluetoothctl connect "${1:-}" >/dev/null 2>&1 || true
    ;;
  battery)
    shopt -s nullglob
    for bat in /sys/class/power_supply/BAT*/capacity; do
      [[ -f "${bat}" ]] || continue
      name="$(basename "$(dirname "${bat}")")"
      cap="$(cat "${bat}" 2>/dev/null || echo "?")"
      st="$(cat "$(dirname "${bat}")/status" 2>/dev/null || echo Unknown)"
      emit "${name}|${cap}|${st}"
    done
    ;;
  timeout)
    if [[ -f "${timeout_file}" ]]; then
      cat "${timeout_file}"
    else
      emit "10"
    fi
    ;;
  timeout-set)
    mins="${1:-10}"
    mkdir -p "${HOME}/.config/hypr"
    printf '%s\n' "${mins}" > "${timeout_file}"
    if [[ "${mins}" == "0" ]]; then
      cat > "${hypridle_conf}" <<'EOF'
general {
    after_sleep_cmd = hyprctl dispatch dpms on
}
EOF
    else
      secs=$((mins * 60))
      cat > "${hypridle_conf}" <<EOF
general {
    after_sleep_cmd = hyprctl dispatch dpms on
}

listener {
    timeout = ${secs}
    on-timeout = hyprctl dispatch dpms off
    on-resume = hyprctl dispatch dpms on
}
EOF
    fi
    pkill -x hypridle >/dev/null 2>&1 || true
    if command -v hypridle >/dev/null; then
      hypridle >/dev/null 2>&1 &
    fi
    ;;
  distro)
    awk -F= '
      $1=="PRETTY_NAME" { gsub(/"/, "", $2); print $2 }
    ' /etc/os-release 2>/dev/null || emit "Arch Linux"
    ;;
  *)
    exit 1
    ;;
esac
