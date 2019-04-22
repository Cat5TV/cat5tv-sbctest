#!/bin/bash

apt update

# Install sysbench if it is not found

  # First attempt: install from included repos
  if [[ ! -f /usr/bin/sysbench ]]; then
    apt -y install sysbench

    # Didn't install from default repos
    # Second attempt: install from developer repo
    if [[ ! -f /usr/bin/sysbench ]]; then
      curl -s https://packagecloud.io/install/repositories/akopytov/sysbench/script.deb.sh | sudo bash
      apt -y install sysbench
    fi

    # Still no success, so abort
    if [[ ! -f /usr/bin/sysbench ]]; then
      # First, clean things up from our attempt
      if [[ -f /etc/apt/sources.list.d/akopytov_sysbench.list ]]; then
        rm /etc/apt/sources.list.d/akopytov_sysbench.list
        apt update
      fi
      # Now, report the issue to screen and exit
      echo "sysbench is not yet available on this build."
      exit
    fi
  fi

# Good to proceed, begin benchmark

if [[ ! -f /usr/bin/bc ]]; then
  apt -y install bc
fi

if [[ ! -f /usr/bin/php ]]; then
  apt -y install php
fi

if [[ -e /tmp/out ]]; then
  rm -f /tmp/out
fi

echo "Category5.TV SBC Benchmark v1.1"
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

printf "Performing CPU Benchmark... "
cpu=`/usr/bin/sysbench --test=cpu --cpu-max-prime=20000 --num-threads=$cores run | /tmp/benchmark-parse.sh cpu $price`
echo $cpu

printf "Performing RAM Benchmark... "
ram=`/usr/bin/sysbench --test=memory --num-threads=$cores --memory-total-size=10G run | /tmp/benchmark-parse.sh ram $price`
echo $ram

printf "Performing Mutex Benchmark... "
mutex=`/usr/bin/sysbench --test=mutex --num-threads=64 run | /tmp/benchmark-parse.sh mutex $price`
echo $mutex

#printf "Performing I/O Benchmark... "
#io=`/usr/bin/sysbench --test=fileio --file-test-mode=seqwr run | /tmp/benchmark-parse.sh io $price`
#echo $io

echo ""
printf "Total Giggle cost of this board: Ģ"
pricescore=`cat /tmp/benchmark_pricescore`
priceperc=$(echo "scale=2;$price/100" | bc)
giggles=$(echo "scale=2;$pricescore*$priceperc" | bc)
printf "%'.2f" $giggles
echo "

Giggles (Ģ) are a cost comparison that takes cost and performance into account.
While the figure itself is not a direct translation of a dollar value, it works
the same way: A board with a lower Giggle value costs less for the performance.
If a board has a high Giggle value, it means for its performance, it is expensive.
Giggles help you determine if a board is better bang-for-the-buck, even if it
has a different real-world dollar value. Total Giggle cost does not include I/O
since that can be impacted by which SD card you choose. Lower Ģ is better.

See https://gigglescore.com/ for more information.
"

# Clear the test files
rm -f /tmp/test_file.*
rm -f /tmp/benchmark-parse.sh
rm -f /tmp/benchmark_pricescore
