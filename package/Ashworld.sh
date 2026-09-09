#!/bin/bash
# Ashworld Windows Java/libGDX adaptation for PortMaster. Experimental, AArch64.
# Runtime arrangement follows BinaryCounter's Westonpack LibGDX example:
# https://github.com/binarycounter/Westonpack/wiki/LibGDX-Example
# SPDX-License-Identifier: MIT

ASHWORLD_SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
for pm_candidate in "${ASHWORLD_PORTMASTER:-}" "/PortMaster" "/opt/system/Tools/PortMaster" "/opt/tools/PortMaster" \
    "/mnt/mmc/MUOS/PortMaster" "$XDG_DATA_HOME/PortMaster" \
    "$ASHWORLD_SCRIPT_DIR/PortMaster" "/roms/ports/PortMaster" "/roms2/ports/PortMaster" \
    "/mnt/SDCARD/Ports/PortMaster" "/mnt/SDCARD/ports/PortMaster" "/storage/roms/ports/PortMaster"; do
    if [[ -f "$pm_candidate/control.txt" ]]; then
        controlfolder="$pm_candidate"
        break
    fi
done
if [[ ! -f "${controlfolder:-}/control.txt" ]]; then
    printf '%s\n' "Ashworld: PortMaster was not found. Install or update PortMaster first."
    sleep 5
    exit 1
fi
# Keep the chosen runtime location even if control.txt changes controlfolder.
ASHWORLD_PM_ROOT="$controlfolder"
source "$controlfolder/control.txt"
controlfolder="$ASHWORLD_PM_ROOT"
[[ -f "$controlfolder/mod_${CFW_NAME}.txt" ]] && source "$controlfolder/mod_${CFW_NAME}.txt"
get_controls
controlfolder="$ASHWORLD_PM_ROOT"

# muOS keeps port data at <card>/ports and menu scripts at <card>/roms/PORTS.
# Prefer data on the script's own card before a firmware default or other card.
ashworld_candidates=("${ASHWORLD_DATA_DIR:-}" "$ASHWORLD_SCRIPT_DIR/ashworld")
case "$ASHWORLD_SCRIPT_DIR" in
    /mnt/mmc/*) ashworld_candidates+=("/mnt/mmc/ports/ashworld") ;;
    /mnt/sdcard/*) ashworld_candidates+=("/mnt/sdcard/ports/ashworld") ;;
esac
[[ -n "${directory:-}" ]] && ashworld_candidates+=("/${directory#/}/ports/ashworld")
ashworld_candidates+=("/mnt/mmc/ports/ashworld" "/mnt/sdcard/ports/ashworld" \
    "/mnt/SDCARD/Ports/ashworld" "/mnt/SDCARD/ports/ashworld" \
    "/roms/ports/ashworld" "/roms2/ports/ashworld" "/storage/roms/ports/ashworld")
GAMEDIR=""
for ashworld_candidate in "${ashworld_candidates[@]}"; do
    if [[ -d "$ashworld_candidate" ]]; then
        GAMEDIR="$ashworld_candidate"
        break
    fi
done
if [[ -z "$GAMEDIR" ]]; then
    printf '%s\n' "Ashworld: data folder missing. On muOS copy ashworld to the SD card's ports folder. On ArkOS keep it beside Ashworld.sh."
    if declare -F pm_message >/dev/null; then
        pm_message "Ashworld data folder missing. On muOS use /ports/ashworld on the SD card. Copy the complete prepared package."
    fi
    sleep 5
    exit 1
fi
mkdir -p "$GAMEDIR/saves" "$GAMEDIR/cache" || exit 1
exec > >(tee "$GAMEDIR/log.txt") 2>&1
printf 'Ashworld experimental port â€” %s\n' "$(date -Iseconds)"

fail() {
    printf 'Ashworld: %s\n' "$*"
    if declare -F pm_message >/dev/null; then
        pm_message "Ashworld: $* See ashworld/log.txt."
    fi
    sleep 5
    exit 1
}

# ESUDO and GPTOKEYB are command-and-option strings provided by PortMaster.
run_privileged() { $ESUDO "$@"; }

weston_dir="/tmp/ashworld-weston"
export JAVA_HOME="/tmp/ashworld-java"
weston_mounted=0
java_mounted=0
weston_started=0
mapper_pid=""
# Called indirectly by the EXIT trap, including startup failures.
# shellcheck disable=SC2329
cleanup() {
    local status=$?
    trap - EXIT INT TERM
    if [[ -n "$mapper_pid" ]]; then
        kill "$mapper_pid" 2>/dev/null || true
        wait "$mapper_pid" 2>/dev/null || true
    fi
    if [[ "$weston_started" == 1 ]]; then
        run_privileged "$weston_dir/westonwrap.sh" cleanup || true
    fi
    if [[ "${PM_CAN_MOUNT:-Y}" != N ]]; then
        [[ "$java_mounted" == 1 ]] && run_privileged umount "$JAVA_HOME"
        [[ "$weston_mounted" == 1 ]] && run_privileged umount "$weston_dir"
    fi
    if declare -F pm_finish >/dev/null; then pm_finish; fi
    exit "$status"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

case "${DEVICE_ARCH:-$(uname -m)}" in
    aarch64|arm64) ;;
    *) fail "This package requires 64-bit ARM Linux. 32-bit firmware is unsupported." ;;
esac
if command -v getconf >/dev/null && [[ "$(getconf LONG_BIT 2>/dev/null)" == 32 ]]; then
    fail "A 64-bit kernel with 32-bit userland cannot run this AArch64 package."
fi
[[ -f "$GAMEDIR/runtime/ashworld-host.jar" ]] || fail "Java host is missing. Copy the complete built package."
[[ -f "$GAMEDIR/ashworld.dat" ]] || fail "Copy your supported Windows game file to ashworld/ashworld.dat. No APK or EXE is needed."

prepare_runtime() {
    local runtime="$1" target="$2" probe="$3"
    # An existing prepared runtime can be reused, but is never unmounted by us.
    if [[ -x "$target/$probe" ]]; then return 0; fi
    if [[ ! -f "$controlfolder/libs/$runtime.squashfs" ]]; then
        [[ -f "$controlfolder/harbourmaster" ]] || fail "Update PortMaster to install the $runtime runtime."
        run_privileged "$controlfolder/harbourmaster" --quiet --no-check runtime_check "$runtime.squashfs" || fail "Could not download $runtime. Check the connection and update PortMaster."
    fi
    [[ -f "$controlfolder/libs/$runtime.squashfs" ]] || fail "The $runtime runtime was not installed."
    run_privileged mkdir -p "$target" || fail "Cannot create the runtime directory."
    # PortMaster supplies a mount replacement on firmware without kernel mounting.
    run_privileged mount "$controlfolder/libs/$runtime.squashfs" "$target" || fail "Could not open $runtime."
    [[ "$target" == "$weston_dir" ]] && weston_mounted=1
    [[ "$target" == "$JAVA_HOME" ]] && java_mounted=1
    [[ -x "$target/$probe" ]] || fail "$runtime is incomplete or incompatible. Reinstall this runtime in PortMaster."
}
prepare_runtime "weston_pkg_0.2" "$weston_dir" "westonwrap.sh"
prepare_runtime "zulu17.54.21-ca-jre17.0.13-linux" "$JAVA_HOME" "bin/java"
export PATH="$JAVA_HOME/bin:$PATH"
"$JAVA_HOME/bin/java" -version || fail "The Java runtime cannot run on this firmware."
"$JAVA_HOME/bin/java" -Xmx64m -cp "$GAMEDIR/runtime/ashworld-host.jar" \
    org.portmaster.ashworld.VerifyGame "$GAMEDIR/ashworld.dat" \
    || fail "Unsupported or damaged ashworld.dat. Copy the supported Windows game JAR described in README."

export SDL_GAMECONTROLLERCONFIG="${sdl_controllerconfig:-${SDL_GAMECONTROLLERCONFIG:-}}"
[[ -n "${GPTOKEYB:-}" ]] || fail "The PortMaster controller mapper is unavailable. Update PortMaster."
export HOTKEY=back
$GPTOKEYB "java" -c "$GAMEDIR/ashworld.gptk" &
mapper_pid=$!

# Firmware supplies the oriented screen size; do not guess from a device name.
# shellcheck source-path=SCRIPTDIR
# shellcheck source=ashworld/display.sh
source "$GAMEDIR/display.sh"
ashworld_display_setup || fail "Invalid display setting. Use auto or WIDTHxHEIGHT in resolution.txt (160..8192 pixels)."
printf 'Firmware: %s; architecture: %s\n' "${CFW_NAME:-unknown}" "${DEVICE_ARCH:-$(uname -m)}"
printf 'Data: %s\nSaves: %s\n' "$GAMEDIR/ashworld.dat" "$GAMEDIR/saves"
printf 'Device: %s; display: %s\n' "${DEVICE_NAME:-unknown}" "$ashworld_display_description"
cd "$GAMEDIR" || fail "Cannot open the game directory."
weston_started=1
run_privileged env "SDL_GAMECONTROLLERCONFIG=$SDL_GAMECONTROLLERCONFIG" \
    "SDL_GAMECONTROLLERCONFIG_FILE=${SDL_GAMECONTROLLERCONFIG_FILE:-}" \
    "SDL_KMSDRM_ORIENTATION=${SDL_KMSDRM_ORIENTATION:-}" \
    "SDL_KMSDRM_ROTATION=${SDL_KMSDRM_ROTATION:-}" \
    "${display_env[@]}" "$weston_dir/westonwrap.sh" headless noop kiosk crusty_glx_gl4es \
    "PATH=$PATH" "JAVA_HOME=$JAVA_HOME" "HOME=$GAMEDIR/saves" \
    "XDG_DATA_HOME=$GAMEDIR/saves" "XDG_CONFIG_HOME=$GAMEDIR/saves/config" \
    "XDG_CACHE_HOME=$GAMEDIR/cache" "WAYLAND_DISPLAY=" \
    "$JAVA_HOME/bin/java" -Xms32m -Xmx256m -XX:+UseSerialGC \
    "-Duser.home=$GAMEDIR/saves" "-Djava.io.tmpdir=$GAMEDIR/cache" \
    "-Dashworld.dat=$GAMEDIR/ashworld.dat" \
    "-Dashworld.saves=$GAMEDIR/saves" -Dashworld.fullscreen=true \
    "${display_java[@]}" \
    -cp "$GAMEDIR/runtime/ashworld-host.jar:$GAMEDIR/ashworld.dat" \
    org.portmaster.ashworld.Main
game_status=$?
printf 'Ashworld exited with status %s\n' "$game_status"
if [[ "$game_status" != 0 ]]; then
    fail "The game stopped with error $game_status. Keep log.txt for diagnosis."
fi
exit 0
