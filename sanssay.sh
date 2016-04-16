#!/bin/bash

printhelp() {
    echo "Output text with Sans's voice. If no text is specified as parameter, stdin is read."
    echo -e "Usage:\n\t${0##*/} [options] [string]..."
    echo -e "\nOptions:"
    echo -e "\t-h, --help\t\tShow help."
    echo -e "\t-s, --silent\t\tDisable sound."
    echo -e "\t-n, --noascii\t\tDisable ASCII art."
    echo -e "\t-w, --whitespace\tTreat whitespace as character (play sound and sleep)"
    echo -e "\t-i, --indent\t\tKeep indentation after passing the ASCII art."
    echo -e "\t-t, --sleep <number>\tHow long to sleep between each char. Default is 0.07. (See also 'man sleep')"
}

newline() {
    LINEWIDTH=0
    echo
    if $ASCII; then
        if [[ $LINE -lt $NUMLINES ]]; then
            ((LINE++))
            printasciiline $LINE
        elif $INDENT; then
            printasciiline $LINE
        fi
    fi
}

# Prints a line from the ascii art
# arg1 = line number
printasciiline() {
    local asciistr="$(echo "$ASCIIART" | sed -n ${1}p)"
    echo -ne "$asciistr"
    ((LINEWIDTH += ${#asciistr}))
}

# Main loop
# arg1 = sound file
loop() {
    local ANSI=false
    local NUMCHARS=1

    while IFS='' read -srn 1 -d '' char; do
        if [[ "$char" == $'\n' ]]; then
            newline
            continue
        else
            if ! $ANSI; then
                if [[ "$char" == $'\t' ]]; then
                    NUMCHARS=$((TABSIZE - LINEWIDTH % TABSIZE))
                else
                    NUMCHARS=1
                fi

                if [[ $((LINEWIDTH + NUMCHARS)) -gt $COLUMNS ]]; then
                    newline
                fi
                ((LINEWIDTH += NUMCHARS))
            fi

            echo -ne "$char"

            if $WHITESPACE || ! [[ "$char" =~ ^[\ \\t]*$ ]]; then
                if [[ "$char" == $'\e' ]]; then
                    ANSI=true
                elif $ANSI && [[ "$char" =~ [a-zA-Z] ]]; then
                    ANSI=false
                elif ! $ANSI; then
                    $SOUND && mplayer -noconsolecontrols "$1" > /dev/null 2>&1 &
                    sleep $SLEEP
                fi
            fi
        fi
    done
}

main() {
    readoptions "$@"

    TABSIZE=8
    COLUMNS=$(tput cols)

    if $ASCII && [[ $COLUMNS -lt $((TABSIZE + $(echo -e "$ASCIIART" | wc -L))) ]] ||
        [[ $COLUMNS -lt $TABSIZE ]]; then
        echo "Terminal size too small."
        exit 1
    fi

    # extract wav
    if $SOUND; then
        local SNDFILE=$(mktemp /tmp/sans.wav.XXXXXXXX)
        echo "$SANSSOUND" | openssl base64 -d > $SNDFILE
    fi

    LINEWIDTH=0

    # print ascii art
    if $ASCII; then
        LINE=1
        NUMLINES=$(echo "$ASCIIART" | wc -l)
        echo -e "$ASCIIART"
        tput sc # restored when text has fewer lines than the ascii art
        for i in $(seq $NUMLINES); do
            # tput sc and tput rc are not reliable here, because if there's
            # not enough space left so that the screen is scrolled down,
            # the wrong position is saved.
            tput cuu1
        done
        printasciiline 1
    fi

    if [[ -n "$TEXT" ]]; then
        loop $SNDFILE <<< "$TEXT"
    else
        loop $SNDFILE < /dev/stdin
    fi

    if $ASCII && [[ $LINE -le $NUMLINES ]]; then
        tput rc
    fi

    echo

    $SOUND && rm $SNDFILE
}

readoptions() {
    SOUND=true
    SLEEP=0.07
    ASCII=true
    WHITESPACE=false
    INDENT=false
    TEXT=''

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help )
                printhelp
                exit
                ;;
            -s|--silent )
                SOUND=false
                ;;
            -n|--noascii )
                ASCII=false
                ;;
            -w|--whitespace )
                WHITESPACE=true
                ;;
            -t|--sleep )
                SLEEP="$2"
                shift
                ;;
            -i|--indent )
                INDENT=true
                ;;
            * )
                TEXT="$@"
                break
                ;;
        esac
        shift
    done
}

# Don't use tabs here, otherwise  you're going to have a bad time.
ASCIIART='        ██████████████████               
    ████░░░░░░░░░░░░░░░░░░████           
  ██░░░░░░░░░░░░░░░░░░░░░░░░░░██         
  ██░░░░░░░░░░░░░░░░░░░░░░░░░░██         
██░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░██       
██░░░░░░░░░░░░░░░░░░░░██████░░░░██       
██░░░░░░░░░░░░░░░░░░░░██████░░░░██       
██░░░░██████░░░░██░░░░██████░░░░██       
  ██░░░░░░░░░░██████░░░░░░░░░░██         
████░░██░░░░░░░░░░░░░░░░░░██░░████       
██░░░░██████████████████████░░░░██       
██░░░░░░██░░██░░██░░██░░██░░░░░░██       
  ████░░░░██████████████░░░░████         
      ████░░░░░░░░░░░░░░████             
          ██████████████                 
                                         '

# base64 encoded sans sound
SANSSOUND='
UklGRrpMAABXQVZFZm10IBAAAAABAAIARKwAABCxAgAEABAAZGF0YSxMAAD//wIA
9f/6//v/+P///wUAAQAJAP3/BADg/+T/0//N/9D/zf/s/+n/EQARABAACwDm/9z/
lv+D/1v/Sf9i/zz/jv+A/9L/vf/S/9L/pP+Q/0z/Lf8d//j+Lf8A/2r/U/+k/43/
pv+n/4z/h/9m/13/YP9P/2//a//D/7r/FgApAJMAmADYAOwAHAEsATcBUQFMAWMB
PAFcARIBLgEBARUBCAEaAR4BKQHZAOwANABDAGH/bv/w/vL+I/8h/73/w/9cAGwA
kACqAHEAgQA7AEEAVwBRAN0A6gC9Ad4BWwKOAmkCowLdAf0BPgFaAQ8BGgFaAYAB
0QH4ARACTQIZAlMCEQJIAhQCTwIwAlsCXwKPAqEC1wLbAhED5AIdA8MC5wKgArkC
iwKnAloCgQL0ARYCgQGZAX4BiQH9AQkCpAK7As8C/gJ6AqcC1wEdAn0BsgFoAaYB
kAHDAZoBxAFHAW0BZQBxAC7/KP87/iP+PP4N/vj+1f7Y/7f/IQADAOj/xv/E/57/
IAAFAO4A5AC9AcgBPgJeAkUCbALnAQwCQgFJAZ0AoAATAA4Apf+0/yb/Ov+u/r3+
bP5q/lv+V/47/i/+wP3D/SD9EP3A/Lj82/zH/DT9G/1w/Uv9Z/0p/S395PzT/Iv8
j/xI/Kr8Zvx//TH9xf6Q/uf/xv9NAD8AHQAkAPD/FwBOAIsA5QBBAU4BrgExAYAB
vwD5AB4AOgBm/3X/tf6n/k/+SP5b/kD+mf6H/sb+lP66/o7+zf6n/jT/K//Z//3/
hwC9AA4BXgGOAdQB3gEsAgACQgLSARYCmQHiAZYB6gHeATwCTwKqArkCGwP+AlYD
+gJpA7ICLQNvAvwCpQJAA3YDGAR0BCUFBQWfBa8ETQX6A4sEVgPzA1QD6QO8A0kE
VATbBMMEQwXUBGsFjwQmBRcEzATqA5QEBwTBBE0EAQU6BPQEwANiBAQDlANQAsoC
oQEPAgIBVgFjAKYA/v8sAMP/8P+1/9v/r//W/9z/9v8zAD0AkACsAOQAFwErAYIB
mQH4AQQCUgL6ASQCMwFgAf7/JgDk/h7/YP6a/ib+av7p/Rz+Q/1d/VP8UPxD+0H7
m/qV+nf6ivrx+vn6jvuC+8j7jPtB+/76L/rl+UL5/fjx+KL4UPn5+Pf5f/k/+sn5
/vmO+Vn5+fj9+Kr4M/ns+Pv5w/nY+qD6S/sd+x77/vqU+nj6B/rl+dL5j/nJ+X35
sPlQ+TT53Pib+DP4PfjV94D4BvgN+Z34iPki+cv5iPlB+g/6L/sW+0b8Ovz1/O/8
9Pzt/Iv8mvxP/F38Svxs/Fn8aPwU/Cv8kfuK+9n6xfor+gD6zvma+RD61/n8+r/6
LPz4+zr9C/3r/dD9hf5q/iX/Cf/a/7L/XwA1AIcAbwBOAEcA2v/m/8P/xf86ADYA
IgENAYUBiwEGARQB8v8RAH7/kf8KABsAOgFBAekB7gGiAZwBmQBsAAH/vP4W/a78
NvvB+lP6rfnv+jn6nfzP+/f9WP31/Wb9q/wm/Ef7ofo8+4T6Jv2H/DQAyP9AAhAC
pwFaAUL+0v1V+pn5Hvhh93D4v/cA+nb59fpu+kr6x/k9+Kr32PUz9Wn0tvMZ9WX0
9Pdl93f7Lvum/YX9YP0w/Y/7J/sp+pT5tPoZ+mP99fzFAZUByAbmBjwLqguMDTgO
Ng3xDVwLAgx7ChgLUwwVDeEPCBEBEmgTnw/oEGAIJAlc/2z/ofgb+Kv25fV3+K/3
A/tm+uj7T/sL+1f6bfqD+bv71vp9/83+owR8BOQJUwr/DfsO/A8xETQPaBBzDFsN
nAldCqsIXgnTCZsKbws+DO8LsAxHC/cLjgo1C4YKJAsMC5MLDQyPDBkO1A4BESMS
ChOIFNwRZhNMDY0OBAjhCCkFzQW0BUwG1AeUCHwJXgqkCaQKjQh1CcwGmgd8BQsG
yAVMBvgHkQh8CjsLBAvIC5oIMAloBKEEMgAbACv9u/xO+7L6u/oJ+mT7svrR/Df8
Y/7r/eX/o/+4Ab4B/gM7BEwGygZiCAQJOAoLC2ULaQzWCtcL2we+CLADMwRmAKoA
3P75/tb95P3h+8j7E/m7+LH2J/Zd9cj0wvRI9KT0UfSN9Tf1Tffp9nX46Pd/98z2
yvT082vyfvFM8mrxSvSB8/T2RfZn+bn40vs3+6v+O/6mAXkB2QMFBD8FsAV/Bg4H
BgiKCBoJbAmdCKUIQwYSBu0CmAJq/wP/8/te+8P44fd89mb1Kvb99Gv3dvZA+ZP4
rfps+gX8FfzT/Sv+CwBsAAoCcgKFA9QDXgSlBJ0E3wRcBJYEUwR8BDEFOAWvBowG
iAdHB0QH7wbOBpEGVgddB9MINglXCg4LigtODMMMkQ0EDsMOZA5HD48NdQ5fDE0N
8gvPDFUMPg3NDMUNEg0iDpINwQ4yDoIPEA5/D54MIg6fChoMOQm/CuMIYQrHCFAK
+AdpCSUGbweoA64EBwHUAQj/sv8l/qn+Vf7R/iH/k//u/2oAvAA/AYoBNQKzAo8D
MARJBQAGMQduB5sI5Af0CPYG9wc9BUEGcQNsBOIBtQJVAPIAdv7k/in8evxs+Yf5
QfYe9iXzrPLj8CjwBPA171TwbO8R8STwcvF38DnxLvBm8Ervbe8x7sfuhe3+7s3t
4e/n7u/wEPBU8Z3w4PAw8ADwXe+B79zu9+9E7zvxbPB78pbx9/IE8qHyq/EE8gTx
gPFu8O3w0u8q8OzuJO/P7SPuv+xD7dvrn+w865bsLutH7dvrWe4e7U/vOe7n7/bu
qfCP79bxkfAz89vxOvQE86f0rPPA9OHzn/S581z0X/MD9PPy2fP08h70cPOT9B30
2PSE9Nv0hvQ49eL0I/bl9aD3lvcD+Uz5O/qr+kz7vPtm/In8bv1W/Xj+G/6J/xn/
hAAYAB0ByAB1ASwBOgL0AbcDcwPUBJcEtQNsA/z/c//o+yD7lPrR+br8MPxO/wH/
b/72/Sj5Kvh/8u7w4O7u7FDwau7P9ST0I/z2+k0Aiv9/ABIAkv0P/YH61vmo+uv5
tP5T/tID7wP+BW8GVQOyA0X9M/3B9hr2mPJy8Uny6PC39Vb0Mfop+fv7G/uX+Kz3
QPLr8BPuUOwb8Fruevc09j//u/4yAkUCjv7G/jz3Fvf88VHx6fP58sf9Qf0tC6oL
uRVIF7EZ1htIGG0axxWLF68VOheeGC4amRxuHnseiSClG6YdXxPgFNIHWQga/ZH8
BPe99ZD2RfXX+eX4ov0e/R4A0f/PAYgBiwSNBK8JMgoMES0StxhrGm0eeiDvHwMi
hBxFHpAVqBa5DmAP/wt2DEsOBw/iEvITiRXBFnAUjxVAES8SLA8REDQQUhEDFKAV
oxjaGogbRh7wGssddRb3GHoPWhF/CMoJHgQIBdUDswQnBy4IoQv3DJAODxA0D5cQ
QA9qENIQ3BF1E6gUxRQ7FvwSeBThDgcQ9wmICmQEbQSD/Rf9QvZ69YnxdfBg8RLw
h/Qk8+v3cPbS+Vr4cvsl+hn/XP6IBZAFPA3nDU0TOBSFFWMWZRMXFEsOww5eCIQI
hwNdA8wAVADj/2L/S//d/m/98Pzz+RP5Iva/9KXz7/EE80DxofP58QP1d/MD93v1
0/hG9+T4LfeA9oz0N/MI8YDxUO+n8rHwDvaC9On60PnDAC8AzQbFBl8L6AtMDUIO
Nw1dDtsM/g00DSgOvg1/DlUNzA3OCgEL1gWqBTD/lf4X+Q/40/Vw9Mf1N/Ra97T1
5fhN90T64fhA/FH7DP+//loCvQIbBu8G8wn3CmgMaw2iC6oM6QfdCOMD4QRSAlAD
dwOLBHEFqwbsBjkIyAc0CVsI3AlVCA8KuwexCaQHywl8CcELZA3UD64RSRTqE7QW
0RKXFSEPrxFEC3cNsQmMCwsLtwzkDZwPGhAEEqYQwRLkDzEStw4REYQN6Q9nDKIO
ZgtzDYMKUQxNCegKSgehCGoEXwVvARkCiP/o/1f/hv9pAF8AYgE5AVkBNQGwALQA
6ABAAS8D0gPtBvYHPQq8C3MLQQ0ICvkL8waUCCADRQR6/woAbPya/Dv6Kfq2+HX4
7/Z+9iv0fvOJ8IjvNO3K62frs+lT647pK+yT6vPssetH7VDsKO1p7I7s6Ot968Tq
WOps6bHpdeik6TDosulI6L3pjuhH6m/p4etZ6zbuu+0P8IXvtfDq7znwN+/z7tLt
Tu0e7O7rx+qT62HqK+zd6s/sROtf7JzqFetD6WPqv+g06+PpLO0i7BDvSO6G8Pjv
8vGw8cjzyfOk9fP12/Zg9wj3nPcr9mP2g/QM9IryUfEd8XPv+PBS7ybyyvCq85/y
gPSW8xT0GPPz8tHxR/Ir8VjzkPKW9n32Kfvf+5b/0ACFAsQDvAOeBKED8wPSAskC
MQLtAYwCUQImBBgEwQXpBVkFgAUpAhoC3f2q/V77SPvW+yP8n/0r/rv9Pf7c+vj6
UPb/9QrzXfIn81ryk/bB9ZP63Pnw+xz7Tvki+PT0RvMD8xrx4/VU9AT8J/tMATMB
7wIuAyABYgEl/iH++Pux+4r7AfuM/PH7tP0d/RH9Wvxq+U/43/Mo8lPvOe3Y7b3r
1O4P7d7vS+547+vtZO7K7LPuQO348f3wjPhA+McBRgLiCyYNVBQXFvkYwhqhGR0b
tRjrGQoZcRqHG3Md3B1YII0cCR9sFWwXzgnWCmH9kv1p9P7zCvGC8KryTfJs9lj2
lPmC+Qb74/p1/Cn8JwDY//sGzQbzDhMPHhWwFQUY8hg8GGoZMRdPGMIVpxZjFBMV
zhOcFIwUvhXrFYoXKhbyF4wUIRZPEo0TrhHKEnQT0RR/FmMY7BhUG0YZ3hu6FvsY
ghEFE5ILTgw8CJgIhQnzCdwNsg6PEbQSVhKGE08RMxLYEFYRrxHoEbkS/RIOE6UT
sBKXE2gRTBIaDqMOOAglCCIBhAAx+y76mfdK9gP2YfTW9e7zAvcF9VD5e/fY+1n6
Qf44/U0BzwDNBRIGwQrBC9ENZg/JDZ0P3wugDeoJiQtUCMoJPgZ5B10DLgSGALkA
Rf66/dL7ivp1+G32sfQM8ijyIO+G8XDuFfIl73Xy0e/58ZLvdPA47hnu3uvE653p
WOtA6SPuYeyi8zjyXvli+L/9Ev1FAfYAegWDBVUKqwoXDqoOoQ9KEK0PfRCYD48Q
HA8iEIoMXw0vB4kHjQBrABT7hfrK9/b2H/b99B31sPPI9A3zf/W685n3BPYS+875
k/+d/jQEkAPTB3gHwAmxCXUKpwrICiULJQuTC0kLrAtTC7EL3gtGDAwNiQ3YDXAO
MQ3VDZwLOQzpCpALbwwrDV4PXBD9EU8T7xK0FF0SgBTSECMT9A4mEYoNcQ9uDQkP
vA5BEF0QABIVEecS2BC1Eq8QXxIaEaUShBEKExsRsRIKEKwRBA+ZEBcOpw9rDN4N
gwnGCiYG/gZ2A9oD5QHbAc0AhgDR/3b/Nf/0/qL/h//7ACEB2gJCA90EkAXJBs8H
MwiSCY0IQQoCCNYJKAfuCFwG6AceBWEGuAK2AzT/7/8++7D7bfeE97rzcfNf8Lfv
0O3R7GDsPeuk62fqB+u86ZHqGuml6vboMOtU6ZnrqOmR653pQus+6Rrr5ejb6oDo
ZeoE6Bzq4ueo6q/o5esn6tTsN+u07C7rJ+yl6jTsyOoe7dDr5+3I7M3ttez67Mnr
K+y/6ofr9emh6gbpWum35xnofOaG58rlrOfp5Y7ouuYe6lPoReyr6m7uF+3h77nu
jvBb7wnxt+/f8YbwEfPN8ezz2vIA9AHzDvMU8oLxdfAM8A7vre+f7nbwXe+k8Wzw
QfL48KPySfG183Ty5PXP9Dz4Yvfm+Sz5QPuE+iX9a/xE/7v+GADr/+b+K/8P/bD9
qfxq/RX+z/6w/zkA2v9SAKz+Hf9K/bv9Rvxz/AT70/o8+ZD4nvfM9oz3tPbf+D34
kPkD+WH3xva78uLxG+8V7gvwDu8v9af0hPpt+kP8aPwR+wv7efpG+t/8zPz1ADYB
/gNsBM4EMQUyBG0E2AL2AmkAiQDK/Pj8Gfk9+W32efaw9G302fIx8ujwAPAm8GTv
A/Kn8X32ovbC/D39NQQGBbIM6w2AFU0X+xxJH3IhGyR/InIlVSF4JH0fgiI/He0f
mhm7GzUTzRQpCjsLZwDeAMP4n/g09YX0gvWb9Oj3Afe9+gX6+P1o/XwCEgKJCGMI
zg7/DmgT7BOOFVgW+BXcFqsVhxb6FOEV3hPfFLcS1hNCEkwT7xK9E0gUDRWFFXUW
MBZyF4AW2hcKF0AYQRhmGecZQRtUGvEb9BeOGf8SNxSiDW8O+QmaCgsIrgiWBjIH
cAXrBfUFcAZDCfIJQQ4yD6kSlRMlFfQVRxb2Fr0WkRdDFiYX0hOMFDIPVw8HCY4I
ZwJ5AUr8Hvun91H2N/Wx8+L0T/MA9nz0JPjt9gn8KftbAg4CWgqxCjwRTxJ4FAIW
9BOKFbERDxNtD5cQuAzUDVoIaAmbAmUDdv3I/UX6D/pG+I/3NPYg9Xj0GPOI9BDz
fPb89B34pPbO91z2e/b79C72r/Ts9oD1efYQ9YnzC/LG7y7uP+7K7CjwD+8x9ILz
mPgw+OP81Py2ARoCAAf0B7cLJg2nDlQQtg9+EZIPOhHPDjEQAQ3SDUsJeAmrAysD
h/1//MH4Rvcg9lL0JvUl8/v0EfPN9R70JvjR9vT7Avs/AMX/UQRPBAQIgQh2C08M
+A3iDmYOGg+CDMsMdwlrCS8HBQeABlgGxwaQBuIGZQZmBrEFLQaNBesG0QbRCEoJ
LwsYDIkNtA6aD/EQ8xB7EhERohIMEH4Rsw4QEPMNXw9yDRIPbwwSDsgKRAySCdsK
sAntCrAKCgyRC/4M3wtTDSQMew1bDJQNxAusDMQJWQoEBygHdwRrBIcCaQKKAJkA
gP6k/tD8M/1z/O/8U/0D/i3/HQDeATwDbgVPB4UJywvgDB8PDQ79DxcNpg7zClsM
kAjXCdQF3QZoAhUDiv7Z/tX6+PrB96j39vSq9G7y2PGO8OXvA/Be73Tw4+8A8Urw
/fAS8OXwte878c/vo/H77x7xN+9m72XtZe2M60LsveoC7MfqBezw6gnsA+ug7Lbr
BO5c7YXvJe8n8BDwx+/S7xnvGe+U7k3uFu5o7Qzt/Otr6xXqVOnj50vnvuWs5Qvk
0uQY46Tk3+Li5DDjuuUl5IbnRuZb6m3pKO2O7MbuTO4C73zu0u4k7u/uHe4R7zDu
yO7O7R/uCe127ULspuxG60Lrs+nZ6Sbo5elF6F/sAuuD8JTvgvT48zn3C/et+M74
g/nd+Uj60fqj+0X8y/2k/gkAHwG+APYBrP7F/5D6K/ta9mj2/fOg8yf0pvOA9vz1
fvkO+Q/7l/rA+Qj5lfZ/9en0jPNK9xn2k/zh+3oASADX/6n/ifv/+k/3bPb29er0
OfdC9jj5Zfiu+hf6fPs2+7f7wvtE+2X7gfqD+o36dvpI/Fv8Hv+L/2QBDAK7AW4C
NgC1AID9wP1H+vz5svbd9fTzy/L08+zyvvcv96D9jP1JAnICRQRuBB0GYgb+C7kM
vxZnGBkiwSQYKFYrvibfKTQhpSP2G6gdXhiUGa0UnRX2Dr4PkwcUCOL/8P/6+Hf4
q/OX8tTxmPBH9XX0Zv2D/ZMGpQdpDQ8P0hGhEx8W5Rd4G1Id9h/fIQMh4CKMHiog
BRt6HGQYuBluFocX7BOkFF8R0BGoEEoRyhL8E1YWHRj7GCUbJxpsHO8aOh38Gzse
HRwpHtAZcxuSFbEWmhFvEl0PGRD4DasOxQs0DBoJRQmACLgIsQuGDG4RLBNRFtwY
Thg0G8EXqhr0FZsYLxNeFQoPoRAMCvgKTAWdBdwAiwCv+5j65/Xd8/fxQ+/R8vbv
JPjS9c/+NP3gA/kClAc5B6IL7gsjEAwRyxI9FNcRdRMeDqEP7AkjC1gGJQd2AqUC
X/2+/MD3UfZP80XxCPGv7oDwEe7j8IPuqPFb72/yVPCj8rnw5vFU8Nrwk++C8JXv
IfF+8KbxL/H28HHwhe/D7gDvGe7N8A/whfQ/9NT49vjG/BP9UgCVAJ4D6QM9BsYG
mwdyCL0HkAjwBoEHYwWVBe0CygJ6//z+e/uk+tP3rPYn9dzzr/N78irzEfJK823y
A/Rh8271IfWr96b3iPrS+tv9av4jAQUC1AMHBTUFmQZGBaMGxwTqBb0EpAVcBRoG
/AWmBuAFlAZZBRcGWQUnBn4GSwdZCCQJHwrbCnELHAx6DDINsw18DgoP4w/7D9QQ
ChDjEDQPKhAFDjMP/AxkDk8MwA3nC00N0wswDf0LXA3JCzQN0AogDHwJmAp9CHUJ
RwgbCQcItQiZBgoH5gM/BLQBRgIzATsC8wFzA5sCRwTMAmIERQOdBL8E5gULBx8I
wwnUCnIMew1vDkEP4g5FD5UNgw2VCzwLtwllCbEHlweGBJ4EBABPAHP73/vT90/4
J/Wi9fHyYvMd8Xvx9u898G/vce9S79vute+t7sbwU+/78WfwVvLW8HjxH/BY8A/v
1e/B7ufvKe+L71HvXe6E7uTsRe027Lbsz+xk7VTu6+6b7xDw/O8F8Gvv7u7W7uTt
ne5f7VDu6uwp7bHra+vy6Trqx+gK6rjoMur16NfpvOg26TLoPOlO6BbqLOkk6zHq
6+vX6qTsaetU7eHrde3R65js0+pX63HphuqH6CXqF+iO6ZHnxugM58HoSeff6bHo
deth6njsausC7dTr9O2z7NXvoe5c8lnx4/Qc9N/2Fva799T2dPdQ9uH2x/VF9032
lvjV9z75jPgG+Dr3wfXT9KH0n/OK9Yv0JPdK9rb37PbN9vL1RvUo9NbzdvLW8kTx
i/IO8e/yrfFX8yDytvJI8T3xYO9i8EfuQfFN73jz6PHM9Zf07PfV9j/6O/m4/Nr7
nv4V/q3/hP+wAMIA3AH5AREC4QGr/wn/FvvQ+Xb2vPS0893x/PJK8YHz9vEE9Xbz
M/iS9mn9AfyMBLwD6wwEDXcVkxbtHOEeECKnJKQkhycsJRQoFSS3JgMhOyN4Gygd
tBPDFNIKHgsyAqoBXvsK+qL3r/WM92j1XPqJ+G3+Q/2yAiYCdgc4B2YNZw14FNIU
LBsrHOAffiGWIaYjziDxIm8efCCoG3YdOBnNGtoXWhmpF2EZKBhBGncYuhpOGGQa
WBgJGlAZ1BrzGoAc5RuAHScbmhzNGLUZUhWRFd4QjBDZC0ELtAcxBzwGDwavB+EH
XwrYCosMRA1SDjUPvxDrEfwTZBXqFo0YihhBGsUYYBpaF5QYhRMkFPEM+ww9BcUE
3f4M/uz66PnI+NL3v/f19gj4kPcT+gX6j/0F/tYBygKsBhAI6gulDZ0QkxJiEzUV
QBO1FJIQZBEPDFAMqwZWBlABiAAV/br7D/o3+Fr3D/Uk9JnxL/GQ7i/wqu2j8Xzv
NvSN8iP24PQT99P1nfcw9iX4dPYQ+GD2Pveh9VL25vRr9g31qPc29lj5vvfq+jX5
mPwI+wH/y/1VAoMBAAZ6BQwJwQifCpgKfAqsCvQIOQmPBqQGlwN9A/f/rP/F+037
lffY9m30TPME84fxOPOC8ZD0wfKe9tH0rPnp97v9Lfw6AgEB9QUzBe4HgAcdCM0H
PgfpBjMG7wVfBVwFbgTKBCoDuwNqAQwCCgCgAMX/cwA2AR0CJwRdBdUHWwliC0IN
FA5kEIwPTBL0Dw0TGRAzEz4QFBPsD2gSng73EDkMuA6MCSQMjgf+CYgGgQg7Br4H
YQa4B0IHngilCCUKwAlsC8IJqQv9CBwLfwi5CsUI6woDCSILJQhdChAGiQgUBLIG
lgMvBhAFnQfaB1IKhQoiDRkM1Q6TDHcPBQ3sD0IONBHLD9gSGhBVE+kNRxGlCREN
zQQKCJ4AjgNH/eP/n/ra/Hb4X/rF9lr4KfVt9ozzbPRw8uDyxvKy8qv0KPQI91T2
Y/jU9z74CPhI9z33OPYK9iT1pvTY8yDzcPLn8Y/xUvFQ8VHxLfEW8Z/wF/Du7+Xu
/e+e7gPxqe878g7xlfKQ8efx3vDf8LLv9++n7vbupe2v7ZTsjeyr6/HrRutc67vq
Hupp6ZPov+dC6F3nsenN6HPrnuqs673qXuo+6WTp8+e86Rzod+qx6BHqUujl6Drn
Tei15qXoBufH6BvnSOi/5rHoc+dS62nq1u4c7nHws+9F75Tu4O1e7d7uku7x8bLx
XPQP9Nn0ivSS9G709PTx9Hn1YvUR9cz0VPQk9DL1Y/V49yv4lvhc+Xn24vbn8t7y
VfFD8cfy0/JD9Ej0+vKC8gXw9e6E7g7teO/W7Y7wpu4d8Nft9e+A7bTyjPCi9/v1
9fqR+bf6OPkq+aj3ivln+JX7B/t7/DD8Ovu2+v75MvmQ+sz5Hfue+o34//dZ8zby
pe/Z7RTxLO/m9p71Mf2q/CABBAFTAzUDZQZbBgEMggxuE8UUbBqFHNYebSEmIAoj
yB7AIQAbrh3GFLkWWw2JDqkHfAhQBUQGHgQ4BfP/oQBw+Eb41vLt8Y30rvO+/JH8
bQUvBrkKPwx2DoAQvhMeFlIZuRtEG3sdKxk5G40X0xnHGZkcSR2BIPscEiBUGLsa
fRRAFp0VEhf4GbMbuRzHHkIcpx6BG/QdxxwoH0EeZyCdHGke6xd/GfkTjRUvE+wU
gxNMFVgR4BKbDLsNPgkLCowKNQslD+QPFRP1E1sUhBWtFBIW+xV5F1UXdxjQFW4W
3hAKEWMLaAteCG0IDgcVBzAEBgQD/2T+tPqu+en6qfnJ/qv9WAKWAbkDcgNmBX0F
5wlECoQPDhAGEpQSHhCmEMUMMg2QCusKPghxCGkDJQOX/Ln7Lfes9bj04vKl86Tx
9fHp70DwHu4d8OXtOPHn7uLxiO+B8SjvWvE2713ygfCt8yLyzvNN8k3ysPAQ8Czu
YO5C7GXuN+yY8JPuU/Sy8hb4x/bj+tT5J/0z/Ob/E//qAlcCKgXYBMIFqgXTBLQE
kwI8Ah3/a/7y+vb5QPcM9rL0JfOw8prwdfDV7VzuhOvZ7SXrXe8A7UXyJfB99Xnz
pvjk9qj7Y/o6/n39z/98/2cAMgBkAC8AJwD7//X/yf/c/5v/wP8+/83/Ef/YAPb/
SQN0AlgGowWtCCoIKgrhCfgL9AvzDh8PBxJTEqUTARSkExAUCROLEzAStRJvEL0Q
kw2ZDesKqgpwCTEJlQhaCDEHEQeqBb4FdQX4BcsG2wcLCGkJ4wcnCfoGDQjYBuIH
rQcRCZEIRAoQCc4KrQkVC7oKwQukC2YM6guqDBgM9QwSDRQO9A44EPsQiBJ4ElwU
PBNxFU4TthVhEuMUQxCrEh4NQw+0CXELmgblB8wDvgSoAFIBBv1g/Z35ovmR9073
xfZ49iL2B/b79DT1UfTL9D310/Xi9rb3ffeo+J32K/j59aj3pfb/90b3F/gq9pL2
7/ND9P3yPfO787XzUfSt81TzJ/Ia8sPwXPIl8XfzYPJb8z7y0/F68KvwIe/C8Crv
qvA1797usO0y7DXrXept6b/pmOg86cbnUOiW5nTnk+Xq5gLlSeZj5N7l/+PM5vTk
EulS5wDrNumd6sfog+iS5rPmr+Q75gzkWubw42vmruMP5xnko+if5RXqKef76RPn
8ujl5SXp8OU87PvoUvFW7lT20fOQ+br3s/pX+fj5zvgO+Lj2OPac9Lf1F/Tj9pH1
QvhM9+737PYS9a7zAfEz7+3tHOwh7aXrQO4T7UfwQO928nPx+vM389XzYvOo8Vrx
Oe+w7jvvYO7I8t/xrPci94v6cfrJ+bj5xPYq9sbzdPKD8s7wNvTS8mv5qvj0/9b/
kwOIA8UAdwBK+Xn4+vLr8QvzRfLO+c75HwMDBCEKqAvsDJYOOQ36Dr0O1RCaE2IW
iRoAHjUgBCSmIlkmRiKYJa8frCJ2Gh8dxBLwFDMLzQzJBrkHDwV2BbUCmQIN/pT9
EPpl+YX6APqe/4z/NgaoBikMDA33EUQTJxjTGeMcBB8UHo8gUBwAH5waTR38Gpgd
kBz9HiYdVB/1G9sdQRoQHPwZuxsZG8UcJhyJHfUbMR3OGzQdyx3CH1Uh0COLIjsl
QR68IA8WUBgnD24RsgwhD00NyQ/VDSMQnQ2bDzUO4w9IENcR4xKGFD8VEBeuF7AZ
LhoiHNgapRw0GLsZARN2FFcO3w8DDK8NGAu8DBQJjgpdBYcG9AHfAocBQgJiBC0F
YQhOCYwLyQxcDtkPJRLhExsW3xcIF6wYPROeFPUMJg7YBwcJywTYBWwBNAJr/KL8
QvcR9+7zhvMW8prxO/CI75Duje297n7tmvBp7xHy5/C/8XvwVvG277ny3fAP9ULz
aPXO88bySvG/7zXuve8j7l/z8fEp+CX3kPsN+0v9JP0R/z7/LAKoAtgFlAbfB5UI
1gY9B30DeQO8/2r/tPwv/BT6afkz90X20/Om8lrwzu4D7STrQOoq6M/o3+Za6d3n
uOvO6nrv9e4e9M/z4viu+Lz8lfzM/rz+Iv8c/6j+yf7Y/hj/XADIAPECegNWBfQF
UgYNB7gFugayBAoGwQSWBlcGjQiQCBMLkAoMDTYMiA7XDfIP7w71EJMOtBDoDBgP
PgtODaAKPwx/CoQLgQkbCq4HMghIBhwHbAaXB7gHDglBCXgKqQq/CxQMEw0cDQEO
Cw2yDQcMcgzGCwoMgw3lDXgQ/BAqErcSEhF4EU0OvA6FDDANBg05Du8OmxCtEIgS
3BGsEwoT1BQiFAAW9RPZFcURZBOWDrEP/Qt2DDIKKgrnB1QHSAREA3QAD/8s/rX8
mf0c/CT9fvuL+3j5VPnz9gf4v/VE+G32a/kI+On6oPmF/CT7Kv64/Ab/p/1j/kD9
s/y6+xv7Kfow+j35hvmC+IT4gPeI92P2DPfG9fn2kfVi9hv1G/UW9NHzA/Ms8yPy
nvIO8SfxA+/c7pfsCu0Q67/sIOuB7dTriu2F69LrY+mS6ALmWuXW4r7jS+GQ5Bri
FOe75HXpcef06UzoZejX5gPmJeQu5ObhduP94MrjieHx5B3jP+bC5MvmV+U/5pjk
v+X3463m1+Sr6AXn/+mF6ODpuuju6QHpl+ur6gnuzuwd72rt0+7b7A/vPu1g8MXu
KfB07ojsTeoK6F/lnucK5SvsDeqm8NDuG/AC7q3rOekD6bTmEus86Uvu0exI7lrs
VOuy6ILpfeZ26sDntuuC6eLq/eig6d3nKOuy6UbvOe4i8jfx5PDE77ntTuwx7eTr
TvF28Fr3yfYe+0n6CvuI+QD5FPfn9w/2D/mu9yD8Pfv/AIYAYQh/CBoSOxM+G5Md
qR/FIvcdMSHbGboclxhKGygb9h3GHKYfbhjKGoEOuQ8jBDYERP2N/HL5SvjY9lz1
Mfaf9Ir5cPgYAOX/9gWSBgQJzQkBDK8M5hLcE+0c4h6KJJgnciXYKBAh7yMaHCge
NhnGGtIXQBkYF5YYJhjLGcYbxx0GIHIiiyFHJNUfbSISHosgox9GIhgkTSeQJzQr
1yZ1Kh4iXCU2HOseJhdpGSQT6hS+DwwRaQ2DDkMNcQ4nD60QhBEzE64SYBTLEnMU
NRMHFXUUiBYlFV8XVRNxFfgOuhADCmoLdwaNB6AEdAWTAykEQAORA0IEnwQEB6AH
RwpZC7oMIQ5oDg4QyBCZEmYUfhatFwgaDhh/GoEUwRYyDhYQLAeaCLAAgAEQ+yL7
jPbn9V/zYvJY8XDwxu8d717uwe2j7drsT+5c7QjwMe/r8U3xGfO48srzlPM/9CT0
cvRd9CP01fPO8yjzcfSL81H2lfWw+Eb4gvpr+s/7uftz/Vn9HwAcAIADrgNWBqYG
NQeABzQFZgW9AKwAcvvp+kH3EPaK9NbyVvJ38Ijv3O1d7Nnqxuku6Kfo4OYV6UXn
xepQ6aTts+yZ8SHxOfbv9V76HfoF/bT83/2A/YT9CP20/Ar8IPw/+//79fou/CP7
cPxp+6L8u/uG/bn8wv9L/0oDJgO4Bv0GwQhcCXoJWApLClUL3AsNDYoN0w4WDlsP
Kg1gDoMLsAyWCc0KOAduCDMEagU2AVMCWP9zADz/XwCgAMgBygL0A+cEJwZTBrIH
0AY2COwGFQiEB0EI0QhSCRkKogqGCjcLOgoMCy4KEwvsCu4L4wsSDXoMxg0GDVIO
Xg7GD3sQHhIeEv4TdRJRFNcRkBNPEdISmxAAErgO1A8xC+QLYwebB3YEcQRJAj0C
6P/U/2X9Rv0L/An8dPyv/HT99/2X/Sj+Df2W/S/9zP2Q/nT/MwAzAdkAngGMAN8A
MwAZACEAw/+Y/xP/BP5W/ef7Dvtw+pL5XfqN+T/7evru+zT76ftW+6T7cPvU+xX8
CPyV/A77dftx+HP4yPVQ9Qf1QvQI9iD1bPZw9WH0PPPq8HrvmO697EHuEOx87iDs
3O2B6xXtyupu7T3rfu5s7A3uHuw560zp7OfM5ePmbeTv50vlU+iy5TjmruNs4+bg
O+Om4D7moeOj6ffm3OoR6PfqI+io7BbqZ/BA7mjzYPFe8wnxpfHg7tPw2e0J8STu
0O/j7AHs0ej454LkmeYT4zjn3uMD56PjAuVr4bDj399i5aPhJemV5S/sqehG7Zvp
p+3z6W3u3uoR73zrdu6q6lztWOnA7QXqe/CF7ZHzY/Hw8wbyjPB57r7rZOn+6Jzm
2umy56Ds0+rF7kvtGe/F7avuKu0S70XtdPF373b21fRM/qb9Kwi0CJMRJROZF7IZ
MxltGy0YYhrGFwgadxkAHJ0bTR5mGgsdkxOVFWIIYQkt/Rb9t/UB9SnzdvIS9NXz
2fY495r6bfu0/t7/mALxA0wG+QcOCz4NxxGdFEMZixy5HvshCyDXIpId3R9ZGVUb
jRVwF40TUhWxE4oVUBWOF/IW7BmhF0sb/hcQHG8ZpR0zHJ4g0B6BI/MfvCTKH0ck
QR8eI9Ed8yA2GpccsBRSFjEQPBGmD3sQohKvE9IVYxe+FucYUBbWGKMWeRniF/Ua
EBiVG3YWOhp8FEMYlxPdFm8S4BSYDiIQTggGCQcDIQPqAaUBZAQeBOwH7gcdC5kL
mA63D8sSnRS6Fj8ZbBl5HAIbYx7gG1wfBRuAHl4XnhphERYUCQvTDK4FUQb6AKIA
afxQ+0j47vaA9Qv0APSR8mfzB/Kx83XyKvVC9D331PaV+L74gPgc+Zj3WPjd9n33
lPbz9mX2mfY39k32PvYl9rv2SPa09/P2WPmM+Kv7EvsX/sP9e/9R/zP/Lf+4/eH9
Ifx//NT6Tftc+ar5FPcN90302PO88dHwpe9A7nPto+v76snoM+nF5q7pFedp7N3p
n+9c7Vnxne/z8bnwBvMs8g71YfRC9tD1WvUj9YnzkvNh84XzYPV69W33Y/e+93T3
RvfB9kT4efcD+y36vv0c/RP/xv7w//f/9wE+AgoFmwVpB0oIkgfFCC0GhQfLBCgG
IwSABWsDrwSQAZQC4v5q/8X87PyL/Hb8u/22/eb+/f5e/4n/8/8PAIEBpwGfA+4D
5wR/BRQFAwaBBYsGGAcZCBEJyQl+CRQKKAiyCNQGdgdRB/MHVgnkCT8L3gsyDCkN
8AxcDi4O5g+GDz4RARCOEV0P4xAIDrUPFgzADf8IUQryBI0FWQE9AcP/J//1/yT/
VABi/63/l/5Y/jL9dv1O/H/9dPxL/nz9HgCV/+MCvwKHBbIF3QUlBu4CKAOh/pb+
zfue+7v7cvvU/In8Bf2u/Nb7YftW+tT5lvkF+cb5P/nF+kP6cfz7+xT+rv2w/j/+
YP3L/LT61PnX96z29fWK9Cz1gvPv9BjzV/RT8qzyffAd8KvtuO0e6wvtX+oh7qnr
lO9m7ejv3O1p70nte+8u7XDwI+6m8IPuw+637L3ri+lE6sDnZOvO6KPtW+vj7v/s
A+9a7THvVu2C72ft7e6r7HntUOuF7ZLrw/Am70v15vPC9nP1cPPf8SXuFewF62fo
Eesm6FTskulb7e3qLu4A7IjuEey07J/plujy5JXl7+Gk55Tkz+2D62/yfPAX8Rnv
COzZ6bzou+aq6R7oO+wG61vtZeyx7eDs8O5W7gHwY++27a3sXeim5tvk4uKn5wbm
7O7+7cj0P/Rs9uH1Kvei9qf7mvvbA5gEXwvSDEIPDhH1EOwSgBOtFbgWMRmLFwMa
mhOhFUIMcQ3jBEIFpv+D/y387PtF+fT41vab9mn2Rvb3+C/5YP0v/lsBowLiA4oF
JgcLCWIN8Q+xFR4ZRRtQH6cahB6eFagYqhEYFNsRUBQ4FB8XOxVuGMsU1xdlFUQY
ExgKG54a/R2RG1gfxBzQIP0gNCXVJk4rXSnmLYglxSkRHpghPRjmGv4VFBgUFfQW
WBNAFcwRxhOaEogUUxU2F3MXYhkCGDYa1hh/G78b3x5GH8EiZiDqI+QdSSGRGacc
RhUCGB8RRhNnDAEOUwhpCe4G2wfmCOUJYAySDYgP7RBeEiMUUBaHGH0bLB45IFQj
fiLkJbkhOSWtHgYiHxolHY8UBhcfDukPjweHCO8BJQI//vT9Y/zD+zv7Vfrj+aD4
APmL9zz65vjO/Qb9nQFiAfYC+AKpAZkBzv/L/1T/bP+D/8//2/4R/zn9OP0+/CT8
+fzv/I3+vv6Z/9n/AQAwAMcA9ABqAq4CvAMwBGoD3ANsAagBAP/z/jz99PzQ+1X7
zPkl+dH22PWT8yry7/D17jXvzuxF7rnrDu7Q67nu4uwr8J3u7PGB8HrzMvKP9Hvz
MvVU9Jn1/vRI9tf1VvcV9xT43fea90r3EPZ19ej0BfRX9VL0yfbr9cP3Dffg9z/3
R/iS9wn6QPmR/O37nP5M/sn/4f/SABMB3QEcAkwCXwJ3AXEBv/+Z/9j9ff36+2z7
KfqC+bv4JfgS+Kb3F/jC90L48/d2+EL4Bfkk+UD60/r9+9f8yf2+/mP/ggC9AAsC
uQFGA2wC6wMKAz0EtQOfBG0ENwUtBQ8GKwYoB3EHhAiuCMUJYAmICpIJ1QqvCQUL
FgqMC5UKEAyWCiYMxwlRCzwIogldBosHtQSFBYcDHATRAk0DewIVA20CGgN+AhQD
bALlAkcC1QKMAnUDgwPGBGQEwwVGBG8FJwMpBGwCbQOrAqQD1gJ/A5ABwAF5/3P/
sv7E/tD/JwAlAXUByAD/AF//qP+p/lr/Iv82AGr/igDM/rD/Gv7t/lb+R//b/rj/
V/6k/r78JvxI+/n5mfr9+PH5QviR+Kz2vPaf9F31MfOT9L/y8/Ns8kPz4fHZ8oDx
1vKr8XTynPEt8Xjwfu+p7svunu2i7yvu4vA87wLxR+/D7+jtM+4r7Mvsj+oX66To
Memw5gnpn+Y57CXqK/FG753zr/GL8Unv0+036xrtWOoi8GftQPN88BnzLPCa8HDt
xu6b61fuYes+7YDqAupi54fm7+OY5SDjjudT5bDpmueO6WLnuOdE5enmKeSi6Mvl
Suth6Bbs8+iI6gnnZ+m15Vzr5+en77Ls4vJc8NnzivF79XjzM/vp+d8DgAOHCssK
8gtQDFUKeQq7CfIJ4gpVC5cKFwvbBu0GtwEuAbX+4P3k/QH91/u2+or2x/QN8bXu
p/Ba7t32XPU3/5X+NgTuAxsFuQTcBY8Fqgn0CbcOug8hEaISFBDDEdkOuxDzDycS
sxEPFM8QBhOPDWYP5wueDbEOmRDhExYWaReQGesXuxn8F5YZ6xmoG+McBh8wHpUg
Qh2wHy8clB6wHCYfaB0IIOcblx4yGNIafBUyGKMWgRlyGnodER0TIFocNB/UGZQc
NhjzGrMXexqNFigZAhRUFpIRmROTEJ0SaRCREngPthHdDewPRg0XD8sOdBBoEToT
uBPOFasV/hdHGLsaoxsoHikexiBZHvkgShzdHroZHByqF+kZahWIF6cRmhN3DBQO
9AcrCdYFwgaOBWYGygSYBW0CEAPu/0QAWP90/6wAtQDNAfYBfAGyAZ0A2ACvAOMA
iAHBAaUBxAFxAE4ABf+i/rD+Qv4U/8z+9/7g/vb9yP0v/df82v1j/Y3/Jf+mAFkA
CgDJ/2n+CP4f/Zr8hvzb+4z7s/pA+VH4WPZA9UP0DvNH8/DxLvLK8Pjviu6k7TPs
De2I69/uYO2n8VzwqPO98oL01fPs9FL0ovXY9DP2UfUj9kL1WPWK9F30lfO18+by
fvOq8qHzvvL/8/rymvRd83r1KPTN9ob1hfid98n6IPo1/a38R/+s/mQA5/+4AGoA
uACvAM0AwACeAGoAhf89/2P9N/3W+sz62PjA+B/40/fC+E/49vmu+bT6wfqB+tH6
A/ph+mD6pvp9+9T7Zvzz/Fz8Mf0p/Cz95vzk/V/+Nv9F//v/NP/h/yT/9/8sAAsB
sgGRApkCbQPZArkDegN2BKwEyAVmBYEG6ATpBdMDvAQOA/ADWwI6A84AlgG6/lL/
r/0S/nT+1f7e/0cABwCAAJv+Bv/x/GP9hvwg/Vr9Nv6V/qX/j/+2ADgAVwGAAKcB
MQBaAVf/eACf/pH/tf5j/3P/3//+/zUAhv+X/0f+Sv4y/Rb97fzC/GL9N/33/dL9
G/74/Zn9V/2P/Cn8j/sr+xX78PpB+0D7Y/s4+wf7bvqY+o35yPqf+Wb7Tvpe+2L6
LPoM+cn4ZfdO+Mn2yfhW9wX5vPd3+Dv3lfc+9uT2dPUc9qf0z/RR8zLzffHj8b/v
PfGh7lzxle6W8vTvpfQ88u71evOO9LPx9fCr7XXuHOvY7+bs5fOR8VT2X/SH9JHy
J/AS7gft0OqL7GrqRu0k62vtO+tS7Qrr3e2Z62TuDuwj7XvqEurL5tznNeRJ6a/l
c+1v6obw5+15787s4+v46DPqQecG7Zjqb/Kp8I32O/UP+Of2R/lF+Iv83fuqAFIA
VQL0AUwApv+l/dT89P1c/asAegA1AQ0Ba/zY++z0y/OV8Dbv0fGk8Eb1XfQp9lf1
mPTC8//0Q/Qc+sf59gALAXAEsgSEA7sDOwKTAnEERwXcCGkKVAtQDRIK/wvAB08J
igfQCEYJnAp5CgUMXQoVDAALygwdDu4PGhIAFKsToBUREgQUXRBMEqcR1BMjFcYX
3hbkGVUUcxfBD6ASjQ0OEHoP3xEWE6UV8BTKF5wUkhdlFEYXARa9GGgYFBt6GTgc
vRifG7EXrRqWF40aqRd6GnUWERnWEygWdhGLE8oQixKFERMTLxKfEwcSiBOyEVcT
YxIdFFIUKRbYFuYY5hhnG+8Z7hy/GfoceBiqG6AWiRnYFJIXoRMoFs4SBBXcEZUT
YRCGEUkO+w7pC0MMuQnaCUQINQjNB5oHwQfDB1oHtAdFBgkHLQUGBuUEtwWQBUwG
OwYPByUG+wZDBQoGgQQFBZAEzwRgBWcFNgYUBnUGIQb/BZAFRQXOBJwETQT+A/MD
/QINAzMBQgHn/sH+5fyF/KP7Dfvn+hv6uvmw+NP3fva29TD0aPTS8gv0h/Id9J/y
APR/8gf0k/Ki9HrzxPUI9Xz2KfZe9jH26fW69TL26fVZ9/T2RfjD9+X3MPdy9or1
RvU19Eb1JfQK9tz0hPY79UP2/PT19dL0VvZ69Vv3uPZS+M73//ic+Mn5gfn5+rb6
+vuU+9r7Ivuo+qj5e/lR+G75RPg/+gv5u/ph+Tv6vviN+fj33/lo+EX7//l3/Gb7
d/yD+5P7uPo6+2r6DvxW+3v9wPw1/nX9s/3w/MD87/tg/Iv7If1H/Hj+of13/8P+
tf8l/5P/Hv/m/4D/GwG/AJcCWAJ6A1oDTgM8A68CiQJuAhcCuQIpAsUCEgL1ASwB
cwCr/zX/aP66/uz9qP7W/Tz+ef1e/bb8u/xJ/PH8wvzt/QD+2v4p/x3/lf/j/l3/
tf40/yr/qf/4/4sAiwAZAUAAuwA2/5//O/6Y/uP9S/4Z/o7+Lf6a/sf9GP4M/UP9
O/x4/Fz7ovti+qP60fny+Qr6CPrU+r76Bvvh+s/5tPm094n3Bvbh9b31ivVZ9iz2
3vaP9pn2H/by9Ur1u/X69CH2d/WW9un1QvZd9Vz1AvT69DfztPXf84z27PTM9Wj0
O/PJ8aDw/O607wDuPPDC7nnwP+/G74zuLO/E7cLvPu7u8HXvF/Gp7w7wa+5Y72rt
dPBx7s/yHPFT9O7yYfP98X7wxO7V7dDrFe006yLujew578Pt7e5A7aztt+vL7MLq
2+zP6vbsyOq/7DXqb+2s6oDw/+0z9Uvzovha9x75E/g9+ED3OPl/+Cf9+fzIATkC
LgQCBdoDvgS3ApUDSAIiA/EBqwImAH4A2fyR/Pf5QvlC+XL4Jvp3+UX6mPlY+Hv3
4PXI9IH1W/Tp9w73Z/vv+ub90P1r/5T/FQF4AV8D3QNBBcAFBgZcBm0GqwYUCHcI
SAsBDLoO6Q+9EB4S3hBbEmoQ5RHEEGISeBJgFLwU9BZ6Fu0Y4hZ6GdUVdBiuEy4W
ERFdExoPEhFyDi0Q6w6VEGMPPREqDzAReg6PECoOKRC6Dq0QChAVEgMSRBRnFOIW
qxZDGckXVxp2F98ZjxbKGCgWOxhQFjsYLBb4F0cVBxdTFAwWCRTOFUoUFhZrFFMW
ZRRbFsQU5hbDFR0Y4BZ2GWAXHBpUFwoaKBfAGSAXfRmxFuAYYhVvF2wTZRWmEYUT
qxBgEicQsRFLD6gQsA3tDuAL+QyPCpUL8gnzCpgJpgpCCVcKDQn4CQQJpQnRCCQJ
EwhLCCMHUAecBtwGwQYIBzEHiQeHB+QHrAcVCMQHNQi+BzcIZwcRCBEH6wf8BhQI
cgdzCM8Hnwh/BwMIJwaLBi8EjAQhAoECZwCeANv+5f5l/Tr94/uk+3/6I/oG+Zj4
gffi9h/2YPXA9e/0nPbl9SD4ifcn+YP4VPmQ+Eb5Wfit+d74Yvrd+QD7zPpz+2n7
Hfwb/LT8n/yA/Ff8XPsf+yn63vkD+sv53Pq/+qz7qfue+4b78PqZ+kD6tfn5+Xn5
zvma+YD5sPnv+Fv5VfjV+Mj3K/gv94H3cPak9sH14vWf9bT1V/Zt9on3gPdT+BP4
fPjf92v4n/cN+UT4YfrO+dX7WPuX/Bb8kvwM/E/82Pth/AD8xPyA/CX95fwY/dD8
1/yD/NH8WPww/aj8hP3e/Bf9ffwU/If7U/vv+pr7Pvua/Dz8Rv32/Bn98vxw/H/8
IvxC/IH8gPwi/Qf9i/1x/Xr9Zf0//RD9IP2V/Cb9Wfzv/AT8XfyQ+9P7Cfvi+w/7
jvyi+wD9LPyv/AL82/tg+4H7GPsl/Mj7Rf0F/S7+E/5z/nD+U/5D/kH+B/50/iD+
wP6J/rz+uf4+/lD+u/2Q/cH9UP0d/on91P1c/V78Gfyz+n/6LPoJ+sr6q/ra+sD6
SfkH+R/3rPZy9vT1ivc594D4Z/iD9333XfUT9Vb0ufNX9ZT04/Y79h73pfY49sz1
/PWB9UL3wvaz+F34u/h/+Ib3Mfe79jD2Dfd89nD3F/eb9oL27vTd9MXze/OO8//y
WfOc8mDyp/FT8aDwMvGX8NXxW/Er8sjxtPE98fjwUvCQ8K7vYPBr7yLwOe/17zfv
AfBt7wbwcu+Z7+DuCe8q7j3vTe6x8Mnv9PJH8o71HvVO+Cf4NPsg+5/9iP0H/9v+
mP9y/y4ALQAtAVEBAQI2AsYB9wElAEEAsP2R/ff6hPqJ+Nn36PYs9nP23PXo9lv2
UPeT9vD28/Vm9jL16/a+9fD42fc/+0L6o/yn+zf9QfxC/lj9AAAy/zgBgAAlAWwA
+ABOAKcCPQIuBh0GIglrCf8JYwrtCVcKKgu/C8gNrw6lD+QQjA/REMgO5Q8QDxIQ
9A/5EEIPXhB1DHMNmwlXCg4JmAmVChcL2wtmDEMLyAvPCUMKywkyCuQLeQyeDmUP
7w/aEMYPqBDTD6cQKRESEskS4hPREgsURBFdEg4Q8xCyEKIRWhJ+E+oSMhTQEQkT
lxCrEe4QERKmEucTIxSDFYMU0RVXFH0VkBSlFR0VRhY7FYUWhBTAFZ4TrhRXEzIU
kxN2FHETbhQ2EkoThxCQEbgPnBAWEPEQmhB7EfYP3RBwDkUPKw3tDewMmA3RDHoN
HgydDLIKJguFCcwJvwgECRgIRAhWB3UHyQbaBs4G7gZAB2wHvwcKCDAIiwijCB0J
GQmgCWsJCQqZCUIKrQl1Co4JegoWCR8KRwhaCTEHIwjUBZsGNwTGBFICzQJ7ANsA
rP7x/hv9Hv3X+537JPu8+r76PPpB+rL5p/nz+FP5pfiu+Qr5S/q7+YH65flD+pL5
SPqR+f36bfoM/I37rPwr/Mj8L/ze/D78RP2w/LL9JP2L/fr89vxo/JD8F/zp/If8
U/0G/eL8nPw4++z6VfkU+W34LPiH+ET4gPgx+LD3NPed9vj1VvaV9cb2/PUX9z32
2vbt9eL26/Xw9w73nPnO+M76/PkB+yj6AvtB+o77Bvuu/Gz8r/19/RD+2/3d/ZP9
W/0G/df8kPyI/ET8d/w+/GT8MPwf/O37y/ue+7j7m/v7++T7MPwb/B/8D/zz+/z7
Qvxf/AH9I/3F/c79Av72/eH90P3T/ar9Df7T/Tz+7P0W/sn90f18/cL9dP0v/s79
jv5I/rD+df6Q/mH+k/5X/sT+iP7a/qX+nf5//iz+Cv7K/ZH9f/0s/TX93fz3/Ln8
5vyz/Ov8tvzq/Kj8/fy+/IL9Yf1l/mb+Cv8d/wr/Cf/B/qr+zv62/jH/K/8i/yf/
O/4h/vL8p/wB/Jn7jvsL+//6bvo5+o/5oPnm+Kn56PgF+kn5APpO+YT52PgP+Vb4
DflL+E75lPhf+cH4LPm2+PX4jPjy+Hv40/hP+Iv4Bvgv+LD3EPiQ9xj4mPcd+Kb3
Jvi092D46feS+Az4ZPi+97r3+fZL93b2lfe79j/4Xvcz+EX3WPdD9oz2YvXL9of1
e/c99nL3HfZg9hX1ePUx9I71dPQX9v/0vPWP9G70HPOI8yzy/PPR8lP1V/Q29mf1
bfaX9c725/UW+B734Pn0+E/7lfo1/LP7Av2s/DH+5P1l/xr/IgDM/yQAzP/O/2X/
m/8m/7//U//6/5v/0v93/yX/lP5U/on9+f0G/Tz+Vf13/qX9+/07/ev8BPw0/Cf7
cfxa+yj9I/w3/Wb8YPyQ+4D7uvq6++n67PxF/BH+lf1m/hn+gv48/lj/I/8IAQAB
zQL5AucDNQSwBAIFyAUhBlwHvQefCB8J/gh9CacIJglzCNMIwQgUCTcJjAlHCaoJ
2Ag4CUwIhQjnB/oHxAe4B7gHvgfLB+4H+QcmCB0IOgj/BwQIqQejB1oHWAdTB1YH
dAeFB4QHoAdkB48HTQeCB10HnAeaB+YH3gc7CEEIugjcCHAJsQloCnQKSwsCC+QL
ZQs+DMcLrww7DDsNiQynDZ8MwA1+DIYNagxVDWIMSA1QDEwNBQwDDY4Lhgw5CwgM
Rwv9C68LXgwJDL0M9AuoDH8LIgwCC5ML1QpYC7QKRwtnCvkKywlaCkkJxgn5CH8J
rAg/CekHjAjfBnEHFgapBhoGqQakBk4H+wauB8gGfQdoBhAHhwYlBzcH2gcPCKwI
dQgRCXkIGgljCA0JdAgbCW0IDAkkCLkIswc3CE0HzgfyBmQHUQa5BlMFnwU9BG8E
RwNsA4sClgKuAZ8BmQBrAHX/Lf+O/kL+/v2s/YL9Of0I/cD8evw3/Cj88/sb/Oz7
cvxW/AH98/ye/bH9L/5Z/qL+4f4N/z//aP+P/7//z//x/wMAFgAhAAUADwDL/7T/
Nv8I/13+Df5s/QL9lfwT/AP8bfuZ+/b6OvuT+sb6EvpN+p75CfpW+Sr6gfmh+gL6
GvuR+lL73/pZ+/D6fvsc+/P7lft7/C38ufyL/JL8efxz/E38k/xj/P/8tfw0/ef8
DP26/LX8VPyE/BL8kPwG/JT8Avx7/NP7Ufyv+1D8o/tW/Lb7MPyL+937O/ue+w/7
1vtg+2n8Bvz+/Jv8Pf3b/Df93vwq/QL9Wv1A/Z39l/3v/dj9HP4Z/kD+Rf44/kv+
7/0E/pL9j/1I/TD9Nv0K/Tj9/fwW/cj82vxt/K/8LPzL/CX8BP1i/E79sPyR/f/8
+f1r/W/+4v3H/kr+3v5+/uP+nv4Y/9P+bv8w/7j/cv+o/3T/b/87/y3//P4I/8b+
6f6p/qj+eP5r/kj+Iv4P/uD9z/2Z/YP9Yv1G/Tn9If0i/QT9Af3R/M78ifyj/EX8
i/wU/IT8+vuC/On7ivzx+7L8E/zH/CP8n/z8+0/8o/su/JL7ePzt+/D8ifwS/cT8
vPx7/Ez8GvxF/BD8jvxP/KT8W/xJ/Pf70/uX+9P7oPsN/Of79PvC+177A/vI+mn6
Afuw+sL7jvsX/O77Y/sf+zL60/mh+UT5+/ms+YL6QPpY+gP6qPlB+TP5wvhI+d74
Nvni+KX4QPjf93z38feK98n4f/hV+Sf5tviN+JP3U/ds9zD37vje+OX6GfvK+xr8
XfuZ+/X6EPu8+9v7PP2O/R7+mf7S/U7+T/2e/Yr9y/1j/qr+av7W/jf9if2p+8/7
P/s4+w38DvzA/NL8Jvwq/Kj6efrO+Xv5Zfoc+p77d/sQ/PL7dftC++H6l/pP+xn7
a/xY/Pn8AP2g/Kr8U/xh/ED9YP0P/1D/bAC/AI0A2QBmAKsARAGZATQDtgO/BFoF
0AR3BRMEpAQXBLUENwXmBRkG4wZpBSkGrwNWBLQCWQN9AyEExQSQBfYErwXMA3IE
1wJdAz4D3wOVBFkFbAU/BlYFFQYfBcQFowVeBooGcAfgBuoHlAabB3oGewdLB08I
UAiICZcI4QnxBzcJYAeWCLEH4wiKCMEJ7QgiCosIwgkgCEsJQAhbCYAIjwkdCB8J
HwcVCHwGdwfFBskHaweBCGoHcgicBo8HCAbgBmsGPQdxB1UIEwgCCfcH3gjCB5MI
CwjTCMUIhwk4CfQJMAnuCSEJ3glaCSAKkwlmClYJJQqrCGUJKgjYCCUIywgyCNsI
xQdlCOAGZwcyBrIGNgaaBoQG8AZxBsMGrgX1BeIEGQWpBPQEAQVdBVIFvwUEBW0F
cgTRBAcEewQiBKsEaQT2BHcE/ARXBNcEWgTgBLYERQUZBZ8FJQWTBekEPwWuBPQE
sAT5BLgEBwV5BM0EAwRLBIwDyAM5A3UD8QIuA4YCxQISAlQC1gEZAs4BFwLEASAC
fQHlATMBsAE5AcsBqwFLAhACxQL+AbECawEpAt0ApgHJAKcB/ADmASMB/QHSAJYB
YQARASIAywBMANgAiQANAY8AAwFiANcAKACcAA4AgQALAHEABABuAA8AcAD4/2kA
1f9GAHj/9f8c/6j/8f5z/+n+ef/t/nT/4P5x/9T+bv/y/ov/LP+6/z3/xv8b/6n/
6f6B/+n+gv8K/53/G/+n//f+bP+u/iX/Zv7f/jj+sv4a/pD+D/5j/hH+WP4f/k7+
JP5K/ir+O/4x/kf+cf59/rL+2P7r/g3/4v78/r3+uv6w/qr+w/7V/v/+Hf/4/iz/
zv74/ob+rv6J/rX+xP7z/gH/K//4/gz/t/7F/oj+n/6m/sj+5v4K//z+Dv/e/tn+
ov6X/oj+f/5k/nf+Qf5K/gj+CP7w/d795v3Y/eX93v3M/bj9r/2I/aD9X/2h/Wn9
ov15/Zb9bP2E/UP9fv0f/XP9DP1a/QP9Mv3j/Az9wfwB/aX87PyW/Mz8cfyF/C38
Wfzz+1787fuH/Bb8qvw4/Jb8KPxt/PX7VfzP+1b8xPtQ/LH7Ifx9+9X7L/ug++n6
dPux+kj7bfrx+iP6rPrd+ZP6zvmn+tL5mfq3+UT6W/nf+fn4zPnz+Cj6WPmX+tP5
qPrp+U76hvns+Rv51vn5+BD6O/lN+nv5Svp++f75P/mP+cr4F/lQ+Mf46fey+OD3
/vgm+GH5ofhu+a341/gS+Nb38vYJ9wr2B/fz9bj3ofZy+F33dPhf95j3dvZv9jr1
sPVp9K/1UvQg9sf0o/ZC9e/2pfUC97314Pae9Zr2XPWS9lL1J/f49XP4VPfO+dz4
mPq6+YT6wPkr+mv5KvqB+bz6FPpb+8r6m/sS+1f7y/rN+kj6O/qj+bD5E/lN+ZD4
HPlG+CP5Lfgn+Sv4E/kJ+Nf4x/eo+Ib3kvhc96X4Xfe2+HH3wfiL98z4pvf2+Nb3
VvlG+O759/h/+qT50voO+vX6P/pS+6/6PPyo+4b9GP2o/l7+T/8Z/6j/dP/8/8z/
ZwBHAMQAvgAWARcBcwFvAdEBywHrAd4BkQGMASoBFAE+ARwB7gG+AbACfAL+/wIA
AgD9////AwBMSVNULgAAAElORk9JU0ZUIgAAAExhdmY1Ni4xNC4xMDAgKGxpYnNu
ZGZpbGUtMS4wLjI0KQBpZDMgLAAAAElEMwMAAAAAACFUWFhYAAAAFwAAAFNvZnR3
YXJlAExhdmY1Ni4xNC4xMDAA'

main "$@"
