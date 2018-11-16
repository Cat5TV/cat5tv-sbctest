#!/bin/bash

if [[ ! -f /usr/bin/sysbench ]]; then
  wget -O /tmp/sysbench.sh https://packagecloud.io/install/repositories/akopytov/sysbench/script.deb.sh
  chmod +x /tmp/sysbench.sh
  /tmp/sysbench.sh
  apt -y install sysbench
fi

echo "Category5.TV SBC Benchmark v1.0"
printf "Powered by "
/usr/bin/sysbench --version

price=$1
if [[ $price == '' ]]; then
  echo "Usage: ./$0 50"
  echo "Where 50 is the price of this board."
  echo "(can be $50 or 50£ - as long as you always use same)"
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
printf "%'.2f" $pricescore
echo "

Giggles (Ģ) are a cost comparison that takes cost and performance into account.
While the figure itself is not a direct translation of a dollar value, it works
the same way: A board with a lower Giggle value costs less for the performance.
If a board has a high Giggle value, it means for its performance, it is expensive.
Giggles help you determine if a board is better bang-for-the-buck, even if it
has a different real-world dollar value. Total Giggle cost does not include I/O
since that can be impacted by which SD card you choose. Lower Ģ is better."

# Clear the test files
rm -f /tmp/test_file.*
rm -f /tmp/benchmark-parse.sh
rm -f /tmp/benchmark_pricescore
