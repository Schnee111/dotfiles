#!/usr/bin/env bash
# Fastfetch Anime Logo Switcher
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOGOS_DIR="$DIR/logos"

if [[ $# -eq 0 ]]; then
    echo "Usage: $(basename "$0") <logo-name>"
    echo ""
    echo "Available anime logos:"
    echo "  [ASCII / Text Art - Compact & Balanced (10-16 lines)]"
    echo "    - cute_frieren    : Frieren detailed portrait ASCII (16 lines, default)"
    echo "    - anime_profile   : Aesthetic side-profile anime girl (16 lines)"
    echo "    - blushing_girl   : Anime girl blushing with aesthetic script (15 lines)"
    echo "    - megumin         : Megumin (Konosuba) ASCII art (14 lines)"
    echo "    - eevee           : Eevee (Pokemon) ASCII art (16 lines)"
    echo "    - luna_cat        : Luna crescent-moon cat (Sailor Moon) (16 lines)"
    echo "    - jigglypuff      : Jigglypuff (Pokemon) ASCII art (12 lines)"
    echo "    - chiikawa        : Chiikawa cute mascot ASCII art (10 lines)"
    echo "    - anime_face      : Detailed anime face looking down (12 lines)"
    echo "    - anime_wink      : Anime girl winking & smiling (10 lines)"
    echo "    - anime_look      : Anime girl looking forward (11 lines)"
    echo "    - anime_ribbon    : Anime girl with hair ribbon (11 lines)"
    echo "    - uwu             : Anime girl face ASCII art (14 lines)"
    echo "    - frieren_ascii   : Frieren compact ASCII (15 lines)"
    echo ""
    echo "  [ASCII / Text Art - Large (20+ lines)]"
    echo "    - anya            : Anya Forger (Spy x Family) ASCII art"
    echo "    - anime_girl      : Detailed anime girl bust ASCII art"
    echo "    - anime_standing  : Full-body anime girl ASCII art"
    echo ""
    echo "  [PNG Images (Rendered via Kitty Graphics Protocol)]"
    echo "    - rei             : Rei Ayanami (Evangelion) PNG"
    echo "    - frieren         : Frieren PNG"
    echo "    - chibi           : Chibi anime girl PNG"
    echo "    - aesthetic       : Aesthetic anime girl PNG"
    exit 0
fi

case "$1" in
    cute_frieren)     TARGET="cute_frieren.txt" ;;
    anime_profile)    TARGET="anime_profile.txt" ;;
    blushing_girl)    TARGET="blushing_girl.txt" ;;
    megumin)          TARGET="megumin_ascii.txt" ;;
    eevee)            TARGET="eevee.txt" ;;
    luna_cat)         TARGET="luna_cat.txt" ;;
    jigglypuff)       TARGET="jigglypuff.txt" ;;
    chiikawa)         TARGET="chiikawa.txt" ;;
    anime_face)       TARGET="anime_face.txt" ;;
    anime_wink)       TARGET="anime_wink.txt" ;;
    anime_look)       TARGET="anime_look.txt" ;;
    anime_ribbon)     TARGET="anime_ribbon.txt" ;;
    uwu)              TARGET="uwu_ascii.txt" ;;
    frieren_ascii)    TARGET="frieren_ascii.txt" ;;
    anya)             TARGET="anya_ascii.txt" ;;
    anime_girl)       TARGET="anime_girl_ascii.txt" ;;
    anime_standing)   TARGET="anime_standing_ascii.txt" ;;
    rei)              TARGET="rei.png" ;;
    frieren)          TARGET="frieren.png" ;;
    chibi)            TARGET="anime1.png" ;;
    aesthetic)        TARGET="anime3.png" ;;
    *)
        if [[ -f "$LOGOS_DIR/$1" ]]; then
            TARGET="$1"
        else
            echo "Unknown logo: $1"
            exit 1
        fi
        ;;
esac

ln -sf "$LOGOS_DIR/$TARGET" "$LOGOS_DIR/current"
ln -sf "$LOGOS_DIR/$TARGET" "$HOME/.config/fastfetch/logos/current"
echo "Switched fastfetch logo to: $TARGET"
fastfetch
