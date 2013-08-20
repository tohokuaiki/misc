#!/usr/bin/php
<?php
$config_file = dirname(__FILE__).'/list.txt';
$config = parse_ini_file($config_file, true);

$basedir = $config['basedir'];

foreach ($config as $conf_name => $confluence){
    if (!is_array($confluence) ||
        isset($confluence['expired']) && $confluence['expired']) continue;
        
    $path = !isset($confluence['path']) ? sprintf('%s/%s/%s', $basedir, $confluence['version'], $conf_name) : $confluence['path'];
    
    if (!is_dir($path)) continue;
    
    $pgrep_cmd    = sprintf('pgrep -f %s', $path);
    $shutdown_cmd = $path.'/bin/shutdown.sh';
    $startup_cmd  = $path.'/bin/startup.sh';
    
    // down check
    $url = sprintf('http://localhost:%d/login.action', $confluence['startup']);
    $url_check = system_ex("wget -O - --spider -nv $url 2>&1");
    
    if (strrpos($url_check, "200 OK")){
        // ok
        continue;
    }
    
    // down...
    $pid = system_ex($pgrep_cmd);
    if ($pid){
        system_ex($shutdown_cmd);
        system_ex('kill -9 '.$pid);
    }
    
    $pid_file = sprintf('%s/work/catalina.pid', $path);
    if (file_exists($pid_file)){
        unlink($pid_file);
    }
    // startup
    system_ex($startup_cmd);
    echo $startup_cmd."\n";
}




function system_ex($cmd)
{
    ob_start();
    system($cmd);
    return ob_get_clean();
}

