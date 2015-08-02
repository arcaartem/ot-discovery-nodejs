#!/usr/bin/env bash

for i in {1..16}
do
    tmux new-window -n "client-$i" node demo.js
done
