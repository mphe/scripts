#!/bin/sh
curl -s gimmeip.com | grep -oE "([0-9]+\.){3}[0-9]+"
