#!/usr/bin/env bash

# Run a command only after Compiz has started
# Ex: Tilda

OPEN=0;

while [[ -z $OPEN ]]
do
OPEN=$(ps -e | grep compiz);
done

$* 