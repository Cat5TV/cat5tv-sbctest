# cat5tv-sbctest
Scripts to test each SBC we demo with data that can be compared from board to board.

## Understanding Ģ and Ģv2

### Giggles (Ģ)

Giggles (Ģ) are a cost comparison that takes cost and performance into account. While the figure itself is not a direct translation of a dollar value, it works the same way: A board with a lower Giggle value costs less for the performance. If a board has a high Giggle value, it means for its performance, it is expensive. Giggles help you determine if a board is better bang-for-the-buck, even if it has a different real-world dollar value. Total Giggle cost does not include I/O since that can be impacted by which SD card you choose. Lower Ģ is better.

### Giggles v2 (Ģv2)

Like Giggles, Giggles v2 provides a value comparison. However, this number is much more accurate, resulting from LZMA CPU benchmarks provided by 7-Zip (rather than floating point tests from sysbench).

For more information about Giggles, and to compare your results to those of our pool, visit https://gigglescore.com/

## Included Scripts

### benchmark.sh

**Usage:** `sudo ./benchmark.sh 79` where 79 is the USD cost to buy the board you are testing.

This script benchmarks and scores CPU, Mutex, RAM and I/O, plus runs both multi-threaded and single-threaded LZMA 7-Zip benchmarks. Using the data collected, a Giggle (Ģ) Score is generated for the board.

For the most accurate results, it is recommended to flash a vanilla [Debian Base Image](https://baldnerd.com/sbc-build-base/) and then clone this repository to run the benchmarks.

### mysql-benchmark.sh

**Preparation:** A database and user must be configured for your benchmark to run. Don't worry; you will be instructed on how to set this up on first run.

**Usage:** `sudo ./mysql-benchmark.sh`

This script will compile a temporary copy of `sysbench` (so tests from board to board are as accurate as possible). Then, 1 million records will be created in a test database. A total of 8 threads will be used to then benchmark the MySQL database for 1 minute, generating a report at the end.

### Helper Scripts

These scripts are used by the scripts above to help with various tasks. Generally you would not run these manually.

#### parse.sh

Parses the output of sysbench so it can be used more effectively as data.

#### parsecores.sh

This script simply replies to a core switch with how many cores are on that CPU. For example, in a case of a big.LITTLE SoC, passing 0 will tell you how many cores are on the first processor, where passing the last core number (eg., 7) will tell how many cores the second processor contains.
