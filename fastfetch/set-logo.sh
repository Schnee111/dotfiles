#!/usr/bin/env bash
# Fastfetch Anime Logo Switcher
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOGOS_DIR="$DIR/logos"

if [[ $# -eq 0 ]]; then
    echo "Usage: $(basename "$0") <logo-name>"
    echo ""
    echo "Available anime logos:"
    echo "  [ASCII / Text Art]"
    echo "    - cute_frieren    : Frieren detailed portrait ASCII (16 lines, pas)"
    echo "    - megumin         : Megumin (Konosuba) ASCII art (14 lines, compact)"
    echo "    - anime_girl      : Detailed anime girl bust ASCII (original proportion)"
    echo "    - uwu             : Anime Girl face ASCII art (compact)"
    echo "    - anya            : Anya Forger (Spy x Family) ASCII art"
    echo "    - frieren_ascii   : Frieren ASCII art (compact)"
    echo "    - anime_girl      : Detailed anime girl bust ASCII art (large)"
    echo "    - anime_standing  : Full-body anime girl ASCII art (large)"
    echo ""
    echo "  [PNG Images (Rendered in Kitty)]"
    echo "    - rei             : Rei Ayanami (Evangelion) PNG"
    echo "    - frieren         : Frieren PNG"
    echo "    - chibi           : Chibi anime girl PNG"
    echo "    - aesthetic       : Aesthetic anime girl PNG"
    exit 0
fi

case "$1" in
    cute_frieren)     TARGET="cute_frieren.txt" ;;
    megumin)          TARGET="megumin_ascii.txt" ;;
    uwu)              TARGET="uwu_ascii.txt" ;;
    anya)             TARGET="anya_ascii.txt" ;;
    anime_girl)       TARGET="anime_girl_ascii.txt" ;;
    anime_standing)   TARGET="anime_standing_ascii.txt" ;;
    frieren_ascii)    TARGET="frieren_ascii.txt" ;;
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
echo "Switched fastfetch logo to: $TARGET"
fastfetch
