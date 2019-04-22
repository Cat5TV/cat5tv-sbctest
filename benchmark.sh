#!/bin/bash

# Update apt if we might need to install something
if [[ ! -f /usr/bin/sysbench ]] || [[ ! -f /usr/bin/bc ]] || [[ ! -f /usr/bin/php ]]; then
  echo "Looks like this is your first time running benchmark.sh."
  echo "Performing initial setup..."
  echo ""
  apt update
fi

# Install sysbench if it is not found

  if [[ ! -f /usr/bin/sysbench ]]; then

    # First attempt: install from developer repo for latest version
    if [[ ! -f /usr/bin/sysbench ]]; then
      curl -s https://packagecloud.io/install/repositories/akopytov/sysbench/script.deb.sh | sudo bash
      yes | apt install sysbench
    fi

    # No success, try default repos, will probably be older version
    if [[ ! -f /usr/bin/sysbench ]]; then
      # First, clean things up from our first attempt
      if [[ -f /etc/apt/sources.list.d/akopytov_sysbench.list ]]; then
        rm /etc/apt/sources.list.d/akopytov_sysbench.list
        apt update
      fi
      yes | apt install sysbench
    fi

    # Still no success, abort
    if [[ ! -f /usr/bin/sysbench ]]; then
      echo "sysbench is not yet available on this build."
      exit
    fi

  fi

# Good to proceed, begin benchmark

if [[ ! -f /usr/bin/bc ]]; then
  yes | apt install bc
fi

if [[ ! -f /usr/bin/php ]]; then
  yes | apt install php
fi

if [[ -e /tmp/out ]]; then
  rm -f /tmp/out
fi

echo ""
echo "Category5.TV SBC Benchmark v1.2"
printf "Powered by "
/usr/bin/sysbench --version

price=$1
if [[ $price == '' ]]; then
  echo "Usage: ./$0 50"
  echo "Where 50 is the USD price of this board."
  exit
fi

cp benchmark-parse.sh /tmp/
chmod +x /tmp/benchmark-parse.sh

# Run the tests
cores=$(nproc --all)

echo "Number of threads for this SBC: $cores"

# we want the junk to go to /tmp
cd /tmp

# Determine if we're on an old version of SysBench requiring --test=
help=`/usr/bin/sysbench --help`
if [[ $help == *"--test="* ]]; then
  # Old version
  command='/usr/bin/sysbench --test='
else
  # Modern version
  command='/usr/bin/sysbench '
fi

printf "Performing CPU Benchmark... "
cpu=`${command}cpu --cpu-max-prime=20000 --num-threads=$cores run | /tmp/benchmark-parse.sh cpu $price`
echo $cpu

printf "Performing RAM Benchmark... "
ram=`${command}memory --num-threads=$cores --memory-total-size=10G run | /tmp/benchmark-parse.sh ram $price`
echo $ram

printf "Performing Mutex Benchmark... "
mutex=`${command}mutex --num-threads=64 run | /tmp/benchmark-parse.sh mutex $price`
echo $mutex

#printf "Performing I/O Benchmark... "
#io=`${command}fileio --file-test-mode=seqwr run | /tmp/benchmark-parse.sh io $price`
#echo $io

echo ""
printf "NEMS Performance Score: "
nps=`cat /tmp/benchmark_nps`
echo $nps NPS

echo ""
printf "Total Giggle Score of this board: Ģ"
pricescore=`cat /tmp/benchmark_pricescore`
priceperc=$(echo "scale=2;$price/100" | bc)
giggles=$(echo "scale=2;$pricescore*$priceperc" | bc)
printf "%'.2f" $giggles
echo "

Giggles (Ģ) are a cost comparison that takes cost and performance into account.
While the figure itself is not a direct translation of a dollar value, it works
the same way: A board with a lower Giggle Score costs less for the performance.
If a board has a high Giggle Score, it means for its performance, it is expensive.
Giggles help you determine if a board is better bang-for-the-buck, even if it
has a different real-world dollar value. Total Giggle Score does not include I/O
since that can be impacted by which SD card you choose. Lower Ģ is better.

See https://gigglescore.com/ for more information.
"

# Clear the test files
rm -f /tmp/test_file.*
rm -f /tmp/benchmark-parse.sh
rm -f /tmp/benchmark_pricescore
rm -f /tmp/benchmark_nps
