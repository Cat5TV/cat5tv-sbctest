# cat5tv-sbctest
Script to setup each SBC we demo with the same software.


## Benchmark

This tool benchmarks and scores CPU, Mutex, RAM and I/O and provides a Giggle (Ģ) Score for the board.

For the most accurate results, it is recommended to flash a vanilla Debian Base Image (see https://baldnerd.com/sbc-build-base/), then clone this repository and run ./benchmark.sh 55 (where the USD value of the board is $55).


### Giggles (Ģ)

Giggles (Ģ) are a cost comparison that takes cost and performance into account. While the figure itself is not a direct translation of a dollar value, it works the same way: A board with a lower Giggle value costs less for the performance. If a board has a high Giggle value, it means for its performance, it is expensive. Giggles help you determine if a board is better bang-for-the-buck, even if it has a different real-world dollar value. Total Giggle cost does not include I/O since that can be impacted by which SD card you choose. Lower Ģ is better.

### Giggles v2 (Ģv2)

Like Giggles, Giggles v2 provides a value comparison. However, this number is much more accurate, resulting from LZMA CPU benchmarks provided by 7-Zip (rather than floating point tests from sysbench).

For more information and to compare your results, visit https://gigglescore.com/
