#!/usr/bin/php
<?php
$config_file = dirname(__FILE__).'/atlassian_applist.txt';
$config = parse_ini_file($config_file, true);

$basedir = $config['basedir'];

foreach ($config as $app_name => $app){
    if (!is_array($app) ||
        isset($app['expired']) && $app['expired']) continue;
        
    $path = !isset($app['path']) ? sprintf('%s/%s/src/%s/%s', $basedir, $app['app'], $app['version'], $app_name) : $app['path'];

    if (!is_dir($path)) continue;
    
    $pgrep_cmd    = sprintf('pgrep -f %s', $path);
    $shutdown_cmd = $path.'/bin/shutdown.sh';
    $startup_cmd  = $path.'/bin/startup.sh';
    
    // down check
    $entry_point = '';
    switch ($app['app'])
    {
      case 'confluence';
        $entry_point = 'login.action';
        break;
      case 'jira':
      default:
        $entry_point = 'secure/Dashboard.jspa';
        break;
    }
    
    $url = sprintf('http://localhost:%d/%s', $app['startup'], $entry_point);
    $url_check = system_ex("wget -O - --spider -nv $url 2>&1");
    
    if (strrpos($url_check, "200 OK")){
        //printf("%s => %s\n", $app_name, $url_check);
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

