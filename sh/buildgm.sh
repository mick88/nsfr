#!/bin/bash
T="$(date +%s)"

cd gamemodes

params="-d2"

if ../pawno/pawncc.exe $params nsfr.pwn
then
	T="$(($(date +%s)-T))"
	echo "Built successfully in $T seconds"
	exit 0
else
	echo "Build failed." 1>&2
	exit 1
fi
