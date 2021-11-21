#!/bin/bash

# Simple screenshots tool
# Uses maim and xclip

# Pretty Constants
COLOR_RED="\033[1;31m"
COLOR_GOLD="\033[0;33m"
COLOR_DROP="\033[0m"

SAVEPOINT=""
OUTPUT="Screenshot-$(date --iso-8601=ns)"
USAGE="Usage: $(basename $0) [options] 

A small script to take shot from the monitor.

Options:
    -o, --output <name>     Set filename of the output file without an extension
    -d, --dir <path>        Set output directory
    -s, --selection         Use selection tool to crop the shot
    -h, --help              Display this help
    -v, --version           Display version of the script"
VERSION="v1.1"
SELECTION=false

# Parse params
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -o|--output)
            OUTPUT="$2"
            shift
            shift
        ;;
        -d|--dir)
            SAVEPOINT="$2"
            shift
            shift
        ;;
        -h|--help)
            echo "$USAGE"
            exit 1
        ;;
        -v|--version)
            echo "$VERSION"
            exit 1
        ;;
        -s|--selection)
            SELECTION=true
            shift
        ;;
        *) shift ;;
    esac
done

OPTIONS="-u"
if $SELECTION; then
    OPTIONS="-s $OPTIONS"
fi

# Obtain the savepoint of the images (directory)
if [ -z $SAVEPOINT ]; then
    echo -e "${COLOR_GOLD}WARNING:${COLOR_DROP} Please, specify the savepoint of the images." \
            "Using default one in ${COLOR_GOLD}$HOME/${COLOR_DROP}"
    SAVEPOINT="$HOME"
fi

# Taking a shot
PICTURE="${SAVEPOINT}/${OUTPUT}.png"
maim $OPTIONS > "$PICTURE"
if [ -f "$PICTURE" -a -s "$PICTURE" ]; then
    xclip -selection clipboard -t image/png < "$PICTURE"
else 
    rm "$PICTURE"
fi
