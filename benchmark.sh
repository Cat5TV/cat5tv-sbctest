#!/bin/bash
# Enable UTF-8
printf '\033%%G'

start=`date +%s`

location=`pwd`

price=$1
if [[ $price == '' ]]; then
  echo "Usage: $0 50"
  echo "Where 50 is the USD price of this board."
  exit
fi

# Install sysbench if it is not found

  # Set the version of sysbench so all match
  # Needs to match a release found at https://github.com/akopytov/sysbench/releases
    ver='1.0.17'

  # Compile if not exist
  if [[ ! -f /usr/local/bin/sysbench-$ver/bin/sysbench ]]; then

      # Warn and give chance to abort installation
        echo "sysbench-$ver not found. I will install it (along with dependencies) now."
        echo 'CTRL-C to abort'
        sleep 5

      # Update apt repositories
        apt update

      # Install dependencies to compile from source
        yes | apt install make
        yes | apt install automake
        yes | apt install libtool
        yes | apt install libz-dev
        yes | apt install pkg-config
        yes | apt install libaio-dev
        # MySQL Compatibility
        yes | apt install libmariadb-dev-compat
        yes | apt install libmariadb-dev
        yes | apt install libssl-dev

      # Download and compile from source
        tmpdir=`mktemp -d -p /tmp/`
        echo "Working in $tmpdir"
        cd $tmpdir
        wget https://github.com/akopytov/sysbench/archive/$ver.zip
        unzip $ver.zip
        cd sysbench-$ver
        ./autogen.sh
        ./configure --prefix=/usr/local/bin/sysbench-$ver/
        make -j && make install

      # Clean up
        cd /tmp && rm -rf $tmpdir

      if [[ ! -f /usr/local/bin/sysbench-$ver/bin/sysbench ]]; then
        # I tried and failed
        # Now, report the issue to screen and exit
        echo "sysbench could not be installed."
        exit 1
      fi

  fi


if [[ ! -f /usr/bin/bc ]]; then
  yes | apt install bc
fi

if [[ ! -f /usr/bin/php ]]; then
  yes | apt install php
fi

if [[ -e /tmp/out ]]; then
  rm -f /tmp/out
fi

prog=$(which 7za || which 7zr)
if [[ -z $prog ]]; then
  apt update && apt -y install p7zip
  prog=$(which 7za || which 7zr)
fi

if [[ -z $prog ]]; then
  echo "Cannot install p7zip. Aborting."
  exit 1
fi

echo ""
echo "Category5.TV SBC Benchmark v2.1"
echo ""
printf "LZMA Benchmarks Provided By: "
$prog 2>&1 | head -n3
echo ""
echo "Floating Point Benchmarks Provided By:"
/usr/local/bin/sysbench-$ver/bin/sysbench --version
echo ""

# Good to proceed, begin benchmark

sysbench=/usr/local/bin/sysbench-$ver/bin/sysbench

echo "Please Wait (may take a while)."

tmpdir=`mktemp -d -p /tmp/`

echo "System Benchmark" > $tmpdir/nems-benchmark.log
date >> $tmpdir/nems-benchmark.log

printf "System Uptime: " >> $tmpdir/nems-benchmark.log
/usr/bin/uptime >> $tmpdir/nems-benchmark.log

echo "---------------------------------" >> $tmpdir/nems-benchmark.log

# Run the tests
cores=$(nproc --all)

echo "Number of threads: $cores" >> $tmpdir/nems-benchmark.log

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
echo "CPU Score $cpu" >> $tmpdir/nems-benchmark.log

printf "Performing RAM Benchmark: " >> $tmpdir/nems-benchmark.log
ram=`${command}memory $threadsswitch=$cores --memory-total-size=10G run | $location/parse.sh ram $price`
echo "RAM Score $ram" >> $tmpdir/nems-benchmark.log

printf "Performing Mutex Benchmark: " >> $tmpdir/nems-benchmark.log
mutex=`${command}mutex $threadsswitch=64 run | $location/parse.sh mutex $price`
echo "Mutex Score $mutex" >> $tmpdir/nems-benchmark.log

printf "Performing I/O Benchmark: " >> $tmpdir/nems-benchmark.log
io=`${command}fileio --file-test-mode=seqwr run | $location/parse.sh io $price`
echo "I/O Score $io" >> $tmpdir/nems-benchmark.log

# Clear the test files
rm -f $tmpdir/test_file.*

echo "---------------------------------" >> $tmpdir/nems-benchmark.log

printf "Performing 7z Benchmark: " >> $tmpdir/nems-benchmark.log

if [[ ! -z $prog ]]; then
  # Multithreaded CPU benchmark
  "$prog" b > $tmpdir/7z.log
  result7z=$(awk -F" " '/^Tot:/ {print $4}' <$tmpdir/7z.log | tr '\n' ', ' | sed 's/,$//')
  echo "Done." >> $tmpdir/nems-benchmark.log
  echo "7z Benchmark Result:     $result7z" >> $tmpdir/nems-benchmark.log
else
  echo "Can't find or install p7zip. 7z benchmark skipped." >> $tmpdir/nems-benchmark.log
fi
echo "---------------------------------" >> $tmpdir/nems-benchmark.log

echo "" >> $tmpdir/nems-benchmark.log

gigglescore=$(bc -l <<< "($price/$result7z)*100000")
gigglescore=$(bc <<< "scale=2;$gigglescore/1")
echo "Giggle Score: $gigglescore Ģv2" >> $tmpdir/nems-benchmark.log

echo "" >> $tmpdir/nems-benchmark.log

end=`date +%s`
runtime=$((end-start))
echo "Benchmark of this benchmark: "$runtime" seconds" >> $tmpdir/nems-benchmark.log

cat $tmpdir/nems-benchmark.log
cd /tmp
rm -rf $tmpdir

