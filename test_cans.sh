#!/bin/bash

CAN1=""
CAN2=""
FP=""

# ./test_cans.sh --can1=can0 --can2=can1 --fp=./bebra.txt
while [ $# -gt 0 ]; do
    case "$1" in 
        --can1=*)
            CAN1="${1#*=}"
            shift
            ;;
        --can2=*)
            CAN2="${1#*=}"
            shift
            ;;
        --fp=*)
            FP="${1#*=}"
            shift
            ;;
        *) 
            echo "unknown arg: $1"
            exit 1
            ;;
    esac
done

if [[ -z "$CAN1" || -z "$CAN2" || -z "$FP" ]]; then
    echo "Missing required args"
    echo "Usage: $0 --can1=VALUE --can2=VALUE --fp=VALUE"
    exit 1
fi

echo "CAN 1:  $CAN1"
echo "CAN 2:  $CAN2"
echo "File:   $FP"

CAN_ID='228'
candump -L "$CAN2,$CAN_ID:7FF" > >(awk -F'#' '{print $2; fflush()}' | xxd -ps -r > copy_file.bin) &
DUMP_PID=$!

sleep 0.1

cat "$FP" | xxd -ps -c 8 | awk -v iface="$CAN1" -v id="$CAN_ID" '{print "(0.000000)", iface, id"#"$1}' | canplayer -t

sleep 0.1

kill $DUMP_PID 2>/dev/null

sleep 0.1

if cmp -s "$FP" copy_file.bin; then
    echo "Done! All good!"
    rm copy_file.bin
else 
    echo "ERROR: Files are not identical!" 
    exit 1
fi