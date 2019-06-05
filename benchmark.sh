#!/bin/bash
# Enable UTF-8
printf '\033%%G'

echo ""
echo "Category5.TV SBC Benchmark v2.2"
echo ""

if [[ $EUID -ne 0 ]]; then
  echo "ERROR: This script must be run as root" 2>&1
  exit 1
fi

start=`date +%s`

location=`pwd`

price=$1
if [[ $price == '' ]]; then
  echo "Usage: $0 50"
  echo "Where 50 is the USD price of this board."
  exit
fi

tmpdir=`mktemp -d -p /tmp/`
echo "Working in $tmpdir"
cd $tmpdir
echo ""

printf "Please wait... "

# Install sysbench if it is not found

  # Compile sysbench

      # Update apt repositories
        apt update > /dev/null 2>&1

      # Install dependencies to compile from source
        yes | apt install unzip > /dev/null 2>&1
        yes | apt install make > /dev/null 2>&1
        yes | apt install automake > /dev/null 2>&1
        yes | apt install libtool > /dev/null 2>&1
        yes | apt install libz-dev > /dev/null 2>&1
        yes | apt install pkg-config > /dev/null 2>&1
        yes | apt install libaio-dev > /dev/null 2>&1
        # MySQL Compatibility
        yes | apt install libmariadb-dev-compat > /dev/null 2>&1
        yes | apt install libmariadb-dev > /dev/null 2>&1
        yes | apt install libssl-dev > /dev/null 2>&1

      # Set the version of sysbench so all match
      # Needs to match a release found at https://github.com/akopytov/sysbench/releases
        ver='1.0.17'

      # Download and compile from source
        cd $tmpdir
        wget https://github.com/akopytov/sysbench/archive/$ver.zip > /dev/null 2>&1
        unzip $ver.zip > /dev/null 2>&1
        cd sysbench-$ver
        timerstart=`date +%s`
        ./autogen.sh > /dev/null 2>&1
        ./configure --prefix=$tmpdir/sysbench > /dev/null 2>&1
        make -j > /dev/null 2>&1
        make install > /dev/null 2>&1
        timerend=`date +%s`
        sysbenchcompiletime=$((timerend-timerstart))

if [[ ! -f /usr/bin/bc ]]; then
  yes | apt install bc > /dev/null 2>&1
fi

if [[ ! -f /usr/bin/php ]]; then
  yes | apt install php > /dev/null 2>&1
fi

prog=$(which 7za || which 7zr)
if [[ -z $prog ]]; then
  yes | apt install p7zip > /dev/null 2>&1
  prog=$(which 7za || which 7zr)
fi

echo "Great job waiting!"
echo ""

if [[ -z $prog ]]; then
  echo "Cannot install p7zip. Aborting."
  exit 1
fi

printf "LZMA Benchmarks Provided By: "
$prog 2>&1 | head -n3
echo ""
echo "sysbench Benchmarks Provided By:"
$tmpdir/sysbench/bin/sysbench --version
echo ""

# Good to proceed, begin benchmark

sysbench=$tmpdir/sysbench/bin/sysbench

echo "Please Wait (will take several minutes)."

echo "System Benchmark" > $tmpdir/nems-benchmark.log
date >> $tmpdir/nems-benchmark.log

echo "---------------------------------" >> $tmpdir/nems-benchmark.log

# Run the tests
cores=$(nproc --all)

cd $tmpdir

# Determine if we're on an old version of SysBench requiring --test=
help=`$sysbench --help`
if [[ $help == *"--test="* ]]; then
  # Old version
  command="$sysbench --test="
else
  # Modern version
  command="$sysbench "
fi
if [[ $help == *"--num-threads="* ]]; then
  # Old version
  threadsswitch="--num-threads"
else
  # Modern version
  threadsswitch="--threads"
fi

printf "Performing CPU Benchmark: " >> $tmpdir/nems-benchmark.log
cpu=`${command}cpu --cpu-max-prime=20000 $threadsswitch=$cores run | $location/parse.sh cpu $price`
echo "Done." >> $tmpdir/nems-benchmark.log

printf "Performing RAM Benchmark: " >> $tmpdir/nems-benchmark.log
ram=`${command}memory $threadsswitch=$cores --memory-total-size=10G run | $location/parse.sh ram $price`
echo "Done." >> $tmpdir/nems-benchmark.log

printf "Performing Mutex Benchmark: " >> $tmpdir/nems-benchmark.log
mutex=`${command}mutex $threadsswitch=64 run | $location/parse.sh mutex $price`
echo "Done." >> $tmpdir/nems-benchmark.log

printf "Performing I/O Benchmark: " >> $tmpdir/nems-benchmark.log
io=`${command}fileio --file-test-mode=seqwr run | $location/parse.sh io $price`
echo "Done." >> $tmpdir/nems-benchmark.log

# Clear the test files
rm -f $tmpdir/test_file.*

echo "---------------------------------" >> $tmpdir/nems-benchmark.log

printf "Performing LZMA Benchmark: " >> $tmpdir/nems-benchmark.log

if [[ ! -z $prog ]]; then
  # Multithreaded CPU benchmark
    "$prog" b > $tmpdir/7z.log
    result7z=$(awk -F" " '/^Tot:/ {print $4}' <$tmpdir/7z.log | tr '\n' ', ' | sed 's/,$//')

  # Average Single Thread benchmark
    # Get the total result from first CPU core
      taskset -c 0 "$prog" b > $tmpdir/7z.log
      result1=$(awk -F" " '/^Tot:/ {print $4}' <$tmpdir/7z.log | tr '\n' ', ' | sed 's/,$//')
      cores1=$($location/parsecores.sh 0)
    # Get the total result from last CPU core (might be big.LITTLE, or could be same core)
      lastcore=$(( $cores - 1 ))
      cores2=0
      if (( $lastcore > 0 )) && (( $cores1 < $cores )); then
        taskset -c $lastcore "$prog" b > $tmpdir/7z.log
        result2=$(awk -F" " '/^Tot:/ {print $4}' <$tmpdir/7z.log | tr '\n' ', ' | sed 's/,$//')
        cores2=$($location/parsecores.sh $lastcore)
      else
        result2=$result1 # Single-core processor
      fi
      # Multiply our first and last result by the number of cores on that processor
      # This assumes each core of the same processor will clock roughly the same
      # which is not literally accurate, but gives us a reasonable approximation without
      # having to benchmark each and every core.
      average7z=$(( ( ($result1*$cores1) + ($result2*$cores2) ) / 2 ))

      echo "Done." >> $tmpdir/nems-benchmark.log

else
  echo "Can't find or install p7zip. LZMA benchmark skipped." >> $tmpdir/nems-benchmark.log
fi

echo "---------------------------------" >> $tmpdir/nems-benchmark.log

end=`date +%s`
runtime=$((end-start))
echo "Benchmark of this benchmark: "$runtime" seconds" >> $tmpdir/nems-benchmark.log

echo "---------------------------------" >> $tmpdir/nems-benchmark.log

echo "" >> $tmpdir/nems-benchmark.log

gigglescore=$(bc -l <<< "($price/$result7z)*100000")
gigglescore=$(bc <<< "scale=2;$gigglescore/1")

gigglescore1t=$(bc -l <<< "($price/$average7z)*100000")
gigglescore1t=$(bc <<< "scale=2;$gigglescore1t/1")

echo "Report:" >> $tmpdir/nems-benchmark.log
echo "" >> $tmpdir/nems-benchmark.log

echo "System Uptime:" >> $tmpdir/nems-benchmark.log
/usr/bin/uptime >> $tmpdir/nems-benchmark.log
echo "" >> $tmpdir/nems-benchmark.log

echo "Number of Threads:              $cores" >> $tmpdir/nems-benchmark.log
if (( $cores2 > 0 )); then
  echo "SoC Contains big.LITTLE CPU:    Yes: $cores1 + $cores2 Cores" >> $tmpdir/nems-benchmark.log
else
  echo "SoC Contains big.LITTLE CPU:    No" >> $tmpdir/nems-benchmark.log
fi
echo "Compiler Time:                  $sysbenchcompiletime seconds" >> $tmpdir/nems-benchmark.log
echo "Multithreaded LZMA Benchmark:   $result7z MIPS" >> $tmpdir/nems-benchmark.log
echo "Single-Threaded LZMA Benchmark: $average7z MIPS Average" >> $tmpdir/nems-benchmark.log

echo "sysbench CPU Score:
     $cpu" >> $tmpdir/nems-benchmark.log
echo "sysbench RAM Score:
     $ram" >> $tmpdir/nems-benchmark.log
echo "sysbench Mutex Score:
     $mutex" >> $tmpdir/nems-benchmark.log
echo "sysbench I/O Score:
     $io" >> $tmpdir/nems-benchmark.log

echo "" >> $tmpdir/nems-benchmark.log
echo "Giggle Scores:" >> $tmpdir/nems-benchmark.log
echo "Multithreaded Giggle Score:   $gigglescore Ģv2" >> $tmpdir/nems-benchmark.log
echo "Single-threaded Giggle Score: $gigglescore1t Ģv2" >> $tmpdir/nems-benchmark.log

echo "" >> $tmpdir/nems-benchmark.log

cat $tmpdir/nems-benchmark.log
cd /tmp
rm -rf $tmpdir

