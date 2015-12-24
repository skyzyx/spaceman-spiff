#! /usr/bin/env php
<?php

// $argf(); similar to Ruby's ARGF
function argf(&$argv)
{
    $contents = '';

    switch (count($argv)) {
        case 1:
            $fp = STDIN;
            break;
        case 2:
            $fp = fopen($argv[1], 'r');
            break;
    }

    while (!feof($fp)) {
        $contents .= fread($fp, 8192);
    }

    fclose($fp);

    return $contents;
};

// Initial cleanup and setup
$input = argf($argv);
$input = str_replace('"', '', $input);
$ips = [];
$dns = [];
$base_length = 220; # Max length of a string before we start prepending/appending

// Where do we start?
echo "SPF-formatted input record" . PHP_EOL;
echo $input . PHP_EOL;

// Recursively collect all of the IP addresses?
function scan_spf($input, &$ips) {
    preg_match_all('/(ip4:([^\s]*))/', $input, $ip4);
    preg_match_all('/(ip6:([^\s]*))/', $input, $ip6);

    $ips = array_merge($ips, $ip4[0]);
    $ips = array_merge($ips, $ip6[0]);

    preg_match_all('/include:([^\s]*)/', $input, $includes);
    $includes = $includes[1];

    foreach ($includes as $incl) {
        $incl = str_replace('"', '', $incl);
        $record = shell_exec("dig TXT ${incl} +short");

        echo '-------------------' . PHP_EOL;
        echo "dig TXT ${incl} +short" . PHP_EOL;
        echo $record . PHP_EOL;

        scan_spf($record, $ips);
    }
}

scan_spf($input, $ips);
sort($ips);

// Take the original input and strip away what we've already resolved
$prefix = $input;
$prefix = preg_replace('/include:([^\s]*)/', '', $prefix);
$prefix = preg_replace('/ip(4|6):([^\s]*)/', '', $prefix);
$prefix = preg_replace('/(~|-)all/', '', $prefix);
$prefix = preg_replace('/\s+/', ' ', $prefix);

echo PHP_EOL;
echo '***********************' . PHP_EOL;
echo 'DNS RECORDS TO CREATE:' . PHP_EOL;
echo '***********************' . PHP_EOL;
echo PHP_EOL;

// Things to apply to every record
$spf = "v=spf1";
$swc = "include:spf0.wepay.com -all";

// We need to start cutting-up the string
$ips = $prefix . implode($ips, ' ');
$idx = 0;
$s = strrpos(substr($ips, 0, $base_length), ' ');
$dns[$idx] = implode(' ', [
    substr($ips, 0, $s),
    preg_replace('/spf0./', sprintf("spf%s.", $idx + 1), $swc),
]);
$ips = trim(substr($ips, $s));

// Break the list into chunks
while (strlen($ips) > 0) {
    $idx++;

    if (strlen($ips) >= $base_length) {
        $s = strrpos(substr($ips, 0, $base_length), ' ');
        $dns[$idx] = preg_replace('/\s+/', ' ', sprintf(
            "%s %s %s",
            $spf,
            substr($ips, 0, $s),
            preg_replace('/spf0\./', sprintf("spf%s.", $idx + 1), $swc)
        ));
        $ips = trim(substr($ips, $s));
    } else {
        $dns[$idx] = sprintf("%s %s -all", $spf, substr($ips, 0, $s));
        $ips = trim(substr($ips, $s));
    }
}

// Display the list
$idx = 0;
foreach ($dns as $value) {
    if ($idx == 0) {
        echo sprintf("# TXT wepay.com (%s chars)", strlen($value)) . PHP_EOL;
    } else {
        echo sprintf("# TXT spf%s.wepay.com (%s chars)", $idx, strlen($value)) . PHP_EOL;
    }

    echo $value . PHP_EOL;
    echo PHP_EOL;
    $idx++;
}
