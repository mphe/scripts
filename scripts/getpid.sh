#!/bin/bash
# get the process id of a window
xprop _NET_WM_PID | cut -d' ' -f3
