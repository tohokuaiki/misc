<html>
<head><title>iptables subscriber</title></head>
<body>
<?php
if (isset($_SERVER['AUTH_TYPE']) &&
    isset($_SERVER["PHP_AUTH_USER"]) &&
    isset($_SERVER["PHP_AUTH_PW"] )) {
    require_once dirname(__FILE__).'/config.php';
    $ip = $_SERVER['REMOTE_ADDR'];
    $list = add_new_ip(get_registered_ip_list(), $ip);
    printf('save your ip => %s [%s]<br /> <p>%s</p>',
           save_ip_list($list) ? 'success': 'failed',
           $ip, date('Y/m/d H:i:s'));
}
else {
    echo "please set basic auth.";
}
?>
</body>
</html>
