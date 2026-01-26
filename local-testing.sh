#!/bin/bash

HOST_DIR="/mnt/mac/Users/alex/dev/bedroom-server"
GUEST_DIR="$HOME/dev/bedroom-server"
sudo mkdir -p "$GUEST_DIR"
sudo mount --bind "$HOST_DIR" "$GUEST_DIR"