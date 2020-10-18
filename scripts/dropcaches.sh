#!/usr/bin/env bash
sudo su -c 'free && sync && echo 3 > /proc/sys/vm/drop_caches && free'
