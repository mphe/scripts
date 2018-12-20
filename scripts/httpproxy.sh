#!/bin/sh

proxy=178.33.39.70:3128

if [ $# -eq 0 ] || [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    echo "Run a given program with a http proxy by setting the http(s)_proxy variable."
    echo -e "Usage:\n\t$0 [options] command"
    echo -e "\nOptions:"
    echo -e "\t-h, --help\tShow help"
    echo -e "\t-p, --proxy server:port\tUse this proxy instead of the default"
    echo -e "\nExample:"
    echo -e "\thttpproxy.sh curl gimmeip.com"
    exit
else
    if [ "$1" == "-p" ] || [ "$1" == "--proxy" ]; then
        proxy=$2
        shift 2
    fi
    export http_proxy=$proxy
    export https_proxy=$proxy
    "$@"
fi
