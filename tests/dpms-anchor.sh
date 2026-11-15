#!/usr/bin/env bash
# Exercise DPMS failures against a fake compositor; never touch real outputs.
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin"
export DPMS_TEST_DIR="$TMP"
sed -e "s|/run/user/\$UID/hypr-dpms.lock|$TMP/lock|g" \
    -e "s|/tmp/hypr-dpms-sleeping|$TMP/sleeping|g" \
    "$REPO/rices/end4/hypr/scripts/sleep_dpms.sh" > "$TMP/sleep.sh"
cat > "$TMP/bin/hyprctl" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$DPMS_TEST_DIR/calls"
case "$1" in
    monitors)
        [[ "$SCENARIO" != ipc-failure ]] || exit 1
        [[ "$SCENARIO" != invalid-json ]] || { echo broken; exit 0; }
        anchor=''
        if [[ "$SCENARIO" == existing || "$SCENARIO" == disabled || "$SCENARIO" == powered-off || -f "$DPMS_TEST_DIR/created" ]]; then
            disabled=false
            powered=true
            [[ "$SCENARIO" != disabled ]] || disabled=true
            [[ "$SCENARIO" != powered-off ]] || powered=false
            anchor=",{\"name\":\"HEADLESS-1\",\"disabled\":$disabled,\"dpmsStatus\":$powered}"
        fi
        printf '[{"name":"HDMI-A-1","disabled":false,"dpmsStatus":true}%s]\n' "$anchor"
        ;;
    output)
        [[ "$SCENARIO" != create-fails ]] || exit 1
        if [[ "$SCENARIO" == delayed ]]; then
            # A successful request alone does not mean a usable output exists.
            exit 0
        fi
        touch "$DPMS_TEST_DIR/created"
        ;;
esac
STUB
cat > "$TMP/bin/sleep" <<'STUB'
#!/usr/bin/env bash
exit 0
STUB
chmod +x "$TMP/bin/"*
export PATH="$TMP/bin:$PATH"
for SCENARIO in create-fails delayed disabled powered-off ipc-failure invalid-json existing created; do
    export SCENARIO
    rm -f "$TMP/sleeping" "$TMP/created" "$TMP/calls"
    result=0
    bash "$TMP/sleep.sh" > "$TMP/output" 2>&1 || result=$?
    case "$SCENARIO" in
        existing|created)
            [[ "$result" == 0 && -f "$TMP/sleeping" ]]
            grep -q 'action = "disable", monitor = "HDMI-A-1"' "$TMP/calls"
            ! grep -q 'action = "disable", monitor = "HEADLESS-1"' "$TMP/calls"
            if [[ "$SCENARIO" == existing ]]; then
                ! grep -q '^output create' "$TMP/calls"
            fi
            # Repeated sleep is idempotent.
            before=$(wc -l < "$TMP/calls")
            bash "$TMP/sleep.sh"
            [[ "$(wc -l < "$TMP/calls")" == "$before" ]]
            ;;
        *)
            if [[ "$result" == 0 ]] || [[ -f "$TMP/sleeping" ]] || grep -q '^dispatch .*disable' "$TMP/calls"; then
                echo "FAIL: $SCENARIO powered off displays or retained sleeping state" >&2
                exit 1
            fi
            grep -q 'HEADLESS-1' "$TMP/output"
            ;;
    esac
    echo "ok: $SCENARIO"
done
