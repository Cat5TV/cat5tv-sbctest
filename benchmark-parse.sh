#!/usr/bin/env php
<?php
  if (isset($argv[1])) $test=$argv[1]; else die('This script is not made to be run manually.' . PHP_EOL);
  if (file_exists('/tmp/benchmark_pricescore')) {
    $pricescore = trim(file_get_contents('/tmp/benchmark_pricescore'));
  } else {
    $pricescore = 0;
  }
  $incoming = stream_get_contents(STDIN);
  $data = explode(PHP_EOL,$incoming);
  if (is_array($data)) {
    foreach ($data as $key=>$line) {
      $data[$key] = trim($line);
      if ($data[$key] == '') unset($data[$key]);
    }
  } else {
    die('No data.' . PHP_EOL);
  }

  file_put_contents('/tmp/out',$incoming,FILE_APPEND);
  switch ($test) {

    case 'cpu':
    case 'ram':
    case 'mutex':
    case 'io':
      foreach ($data as $line) {
        // The time it took to run the test
        if (substr($line,0,11) == 'total time:') {
          $tmp = explode(':',$line);
          $time = floatval($tmp[1]);
        }
        // The number of events during that time
        if (substr($line,0,23) == 'total number of events:') {
          $tmp = explode(':',$line);
          $events = floatval($tmp[1]);
        }
      }
      if ( ($events > 0) && ($time > 0) ) {
        $result = ($events / $time);
        $price = floatval($argv[2]);
        $valuescore = (($price/$result)*3600);
        if ($test == 'mutex') $valuescore = ($valuescore/10000);
        $pricescore = $pricescore + $valuescore;
        if ($test != 'io') file_put_contents('/tmp/benchmark_pricescore',$pricescore);
        echo number_format($result,3) . ' events per second. Price: Ģ' . number_format($valuescore,2) . ' per unit.';
        if (($test != 'io') && ($test != 'ram')) {
          if (file_exists('/tmp/benchmark_nps')) {
            $nps = intval(file_get_contents('/tmp/benchmark_nps'));
          } else {
            $nps = 0;
          }
          $nps = ceil($nps + $result);
          file_put_contents('/tmp/benchmark_nps',$nps);
        }
      } else {
        echo 0;
      }
      break;

  }

?>
