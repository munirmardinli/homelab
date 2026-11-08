#!/usr/bin/env bash

set -e

sudo pmset -a sleep 0
sudo pmset -a disablesleep 1

pmset -g

sudo pmset -a autorestart 1
sudo pmset -a displaysleep 5

# sudo pmset -a disablesleep 0
