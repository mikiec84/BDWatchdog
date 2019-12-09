#!/usr/bin/env bash
cd ubuntu
apt update
bash dependencies/install-dependencies.sh
bash python-dependencies/install-python-dependencies.sh
bash atop/install-atop.sh
#bash atop/install-netatop.sh
bash turbostat/install-turbostat.sh
cd ..
