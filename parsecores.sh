#!/usr/bin/env php
<?php

  // This little script will simply reply to a core switch with how many cores are on that CPU
  // For example, in a case of a big.LITTLE SoC, passing 0 will tell you how many cores are on
  // the first processor, where passing the last core number (eg., 7) will tell how many cores
  // the second processor contains.
  // By Robbie Ferguson // The Bald Nerd
  // https://baldnerd.com/

  if (is_array($argv) && isset($argv[1]) && is_numeric($argv[1])) {
    $core = intval($argv[1]);
    $valid = 0; // assume invalid core until we've confirmed otherwise
  } else {
    die('Usage: ' . $argv[0] . ' 1' . PHP_EOL);
  }

  $cpuinfo = file('/proc/cpuinfo');
  if (is_array($cpuinfo)) {
    foreach ($cpuinfo as $data) {
      if (substr($data,0,9) == 'processor') {
        $tmp = explode(':',$data);
        $processor = trim($tmp[1]);
      } elseif (substr($data,0,8) == 'CPU part') {
        $tmp = explode(':',$data);
        $part = trim($tmp[1]);
      } elseif (substr($data,0,12) == 'CPU revision') {
        $tmp = explode(':',$data);
        $revision = trim($tmp[1]);
        // I have the processor number, part and revision, proceed
        $cores[$part . '.' . $revision][$processor] = $processor;
        if ($processor == $core) {
          $valid = 1;
          $validproc = $part . '.' . $revision;
        }
      }

    }
  }

  // this core is valid (passed by command line)
  if ($valid == 1) {
    echo count($cores[$validproc]); // Number of cores in the processor of the chosen core
  } else {
    echo 0; // no cores in the chosen processor since it doesn't exist
  }

  echo PHP_EOL;

?>
