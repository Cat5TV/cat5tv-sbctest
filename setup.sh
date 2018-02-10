#!/bin/bash

# Install cat5tv-miners to compare monero mining H/s
wget -O /tmp/cat5tv-miners-install.sh https://raw.githubusercontent.com/Cat5TV/cat5tv-miners/master/monero-cpu.sh && chmod +x /tmp/cat5tv-miners-install.sh && sudo /tmp/cat5tv-miners-install.sh

# Install a few packages good for demonstrating
apt -y install gimp ssh htop synaptic kodi iperf stress-ng git

# For iperf (test ethernet speed) see https://askubuntu.com/questions/7976/how-do-you-test-the-network-speed-between-two-boxes
# With iperf server in place at 10.0.0.110: iperf -c 10.0.0.110 -P 10 -t 30

# For stress-ng:
# More great info near bottom of https://www.cyberciti.biz/faq/stress-test-linux-unix-server-with-stress-ng/
# run for 60 seconds with as many stressors as cpu cores, 2 io stressors and 1 vm stressor using 1GB of virtual memory, enter:
# stress-ng --cpu 0 --io 2 --vm 1 --vm-bytes 1G --timeout 60s --metrics-brief

# Install retropie
# See https://github.com/RetroPie/RetroPie-Setup/wiki/Odroid-XU4
git clone --depth=1 https://github.com/RetroPie/RetroPie-Setup.git
cd RetroPie-Setup
./retropie_setup.sh

# Set Locale
apt install language-pack-en-base
update-locale LC_ALL="en_US.UTF-8"
update-locale LANG="en_US.UTF-8"
update-locale LANGUAGE="en_US.UTF-8"
dpkg-reconfigure locales

