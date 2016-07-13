#! /usr/bin/php
<?php
# your host IP address
$myhost   = 'xxx.xxx.xxx.xxx';
$ssh_port = 22;
# ip address to be append to allow ssh list. 
$required_list_file = dirname(__FILE__).'/.ht_add_ip_list';
chdir(dirname($required_list_file));

require_once 'config.php';
$list = get_registered_ip_list();
$list = check_valid_term($list);
save_ip_list($list);

foreach ($list as $l){
    $ip = $l['ip'];
    $cmd = sprintf(
        'iptables -A INPUT -p tcp -s %s -d %s --dport %s -j ACCEPT',
        $ip, $myhost, $ssh_port);
                    # echo $cmd."\n";
    system($cmd);
    $cmd = sprintf(
        'iptables -A OUTPUT -p tcp -s %s --sport %d -d %s -j ACCEPT',
        $myhost, $ssh_port, $ip);
                    # echo $cmd."\n";
    system($cmd);
}
