#!/bin/bash

sudo apt update && sudo apt install openssh-server ufw
sudo systemctl enable ssh
sudo ufw allow ssh
