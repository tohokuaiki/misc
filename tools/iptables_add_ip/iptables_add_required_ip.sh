#! /usr/bin/php
# This script is execute by root with cron
<?php
$myhost   = 'xxx.xxx.xxx.xxx'; // your server ip address
$required_list_file = './.ht_add_ip_list';
chdir(dirname($required_list_file));

require_once 'config.php';
$list = get_registered_ip_list();
$list = check_valid_term($list);
save_ip_list($list);

foreach ($list as $l){
    $ip = $l['ip'];
    $cmd = sprintf(
        'iptables -A INPUT -p tcp -s %s -d %s --dport 22 -j ACCEPT',
        $ip, $myhost);
                    # echo $cmd."\n";
    system($cmd);
    $cmd = sprintf(
        'iptables -A OUTPUT -p tcp -s %s --sport 22 -d %s -j ACCEPT',
        $myhost, $ip);
                    # echo $cmd."\n";
    system($cmd);
}
