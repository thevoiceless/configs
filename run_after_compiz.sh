#!/usr/bin/env bash

OPEN=0;

while [[ -z $OPEN ]]
do
OPEN=$(ps -e | grep compiz);
done

$* 