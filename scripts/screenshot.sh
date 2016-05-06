#!/bin/bash
dir=~/img
name="screenshot$(date +%Y%m%d%H%M%S).png"
import -window root "$dir/$name"
