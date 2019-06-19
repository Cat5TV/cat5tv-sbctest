#!/bin/bash

# Enable UTF-8
printf '\033%%G'

echo ""
echo "MySQL Benchmark Script"
echo "https://github.com/Cat5TV/cat5tv-sbctest"
echo ""

if [[ $EUID -ne 0 ]]; then
  echo "ERROR: This script must be run as root" 2>&1
  exit 1
fi

start=`date +%s`

location=`pwd`

tmpdir=`mktemp -d -p /tmp/`
echo "Working in $tmpdir"
cd $tmpdir
echo ""

# Test to make sure the database is ready
if ! mysql -u benchmark -e ";" ; then
  echo ""
  echo "It looks like you haven't setup the database yet."
  echo ""
  echo "Connect to your database as root:"
  echo "  mysql -u root -p"
  echo ""
  echo "Create the database and user:"
  echo "  CREATE DATABASE benchmark;"
  echo "  CREATE USER benchmark@localhost;"
  echo "  GRANT ALL PRIVILEGES ON benchmark.* TO benchmark@localhost;"
  echo ""
  echo "Then, try again."
  exit
fi

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
        # I will not install mariadb-server in case this is run on a production system (WHY would you do that?!)
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

echo "Great job waiting!"
echo ""

echo "sysbench Benchmarks Provided By:"
$tmpdir/sysbench/bin/sysbench --version
echo ""

# Good to proceed, begin benchmark

sysbench=$tmpdir/sysbench/bin/sysbench

echo "Please Wait (will take several minutes)."

echo "MySQL Benchmark" > $tmpdir/nems-benchmark.log
date >> $tmpdir/nems-benchmark.log

echo "---------------------------------" >> $tmpdir/nems-benchmark.log

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

printf "Performing MySQL Benchmark: " >> $tmpdir/nems-benchmark.log
# Create a table with 1m entries
$sysbench oltp_read_write --table-size=1000000 --db-driver=mysql --mysql-db=benchmark --mysql-user=benchmark --mysql-socket=/var/run/mysqld/mysqld.sock prepare >> $tmpdir/nems-benchmark.log
$sysbench oltp_read_write --table-size=1000000 --db-driver=mysql --mysql-db=benchmark --mysql-user=benchmark --time=60 --max-requests=0 --threads=8 run >> $tmpdir/nems-benchmark.log
$sysbench oltp_read_write --db-driver=mysql --mysql-db=benchmark --mysql-user=benchmark cleanup >> $tmpdir/nems-benchmark.log
echo "Done." >> $tmpdir/nems-benchmark.log

# Clear the test files
rm -f $tmpdir/test_file.*

echo "---------------------------------" >> $tmpdir/nems-benchmark.log

end=`date +%s`
runtime=$((end-start))
echo "Benchmark of this benchmark: "$runtime" seconds" >> $tmpdir/nems-benchmark.log

echo "---------------------------------" >> $tmpdir/nems-benchmark.log

echo "" >> $tmpdir/nems-benchmark.log

cat $tmpdir/nems-benchmark.log
cd /tmp
rm -rf $tmpdir

