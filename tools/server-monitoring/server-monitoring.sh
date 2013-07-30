#!/usr/bin/php
<?php
$now = date('YmdHis');
$results = array();
$config_file = dirname(__FILE__).'/server-monitoring.ini';
$config = parse_ini_file($config_file, true);
$subject = sprintf('サーバ監視結果アラート(%s)', $config['config']['server_name']);
$trouble_server_file = dirname(__FILE__).'/trouble_servers';
$trouble_server_text = "";
$trouble_servers = array();
if (file_exists($trouble_server_file)){
    $trouble_server_text = file_get_contents($trouble_server_file);
    $ts = explode("\n", $trouble_server_text);
    foreach ($ts as $_t){
        $_t = trim($_t);
        if ($_t){
            $_t = explode("\t", $_t);
            if (count($_t) == 2){
                $trouble_servers[] = $_t[0];
            }
        }
    }
}


// self check
if (count($_SERVER['argv']) == 2 && $_SERVER['argv'][1] == "self"){
    $results[] = sprintf("SELF check mode.\ncurrent trouble servers are => \n=====\n%s\n",
                         $trouble_server_text);
    $subject = "(self check)".$subject;
}

require_once 'HTTP/Request2.php';
$req = new HTTP_Request2();
$req->setConfig('ssl_verify_peer', false)->setConfig('ssl_verify_host', false)->setConfig('follow_redirects',true)->setConfig('max_redirects', 5);

foreach ($config['targetserver']['server'] as $url){
    $result = "";
    $url_param = parse_url($url);
    if (in_array($url_param['host'], $trouble_servers)){
        continue;
    }
    $tmp_dir = sprintf('%s/tmp/%s', dirname(__FILE__), $url_param['host']);
    if (!file_exists($tmp_dir)){
        mkdir($tmp_dir, 0775, true);
    }
    try {
        $res = $req->setURL($url)->send();
        $code = $res->getStatus();
        if ($code != 200){
            $result .= sprintf("Response code is not 200 (%d).\n", $code);
        }
        else {
            $html = $res->getBody();
            if ($html) {
                if ($html_before = getLastMonitoredHTML($tmp_dir)) {
                    $html_length = strlen($html);
                    $html_before_length = strlen($html_before);
                    $html_diff1 = $html_length/$html_before_length;
                    $html_diff2 = $html_before_length/$html_length;
                    if ($html_diff1 < $config['config']['beforediff']/100 ||
                        $html_diff2 < $config['config']['beforediff']/100){
                        $result .= sprintf('Diff large diff1(current/before) =>%f, diff2(before/current) => %f',
                                           $html_diff1, $html_diff2);
                    }
                }
                file_put_contents($tmp_dir.'/'.$now, $html);
            }
            else {
                $result .= "get no html...";
            }
        }
    }
    catch (HTTP_Request2_Exception $e){
        $result .= sprintf('Error[%d] %s', $e->getCode(), $e->getMessage());
    }
    
    if ($result){
        $result = sprintf("[%s]\n%s", $url_param['host'], $result);
        $results[] = $result;
        // add trouble-server-file
        $trouble_server_text .= sprintf("%s\t%s\n", $url_param['host'], $now);
    }
}
file_put_contents($trouble_server_file, $trouble_server_text);
if ($results){
    $header  = sprintf("From: %s\n", $config['config']['from']);
    $text = implode("\n", $results);
    mb_language("japanese");
    mb_internal_encoding("UTF-8");
    mb_send_mail($config['config']['checkmail'], $subject, $text, $header); 

}
var_dump($results); 



/**
 * @brief get last monitored html and remove before N logs.
 * @param target dir
 * @param logs num to store
 * @retval string before HTML
 */
function getLastMonitoredHTML($dir, $n = 10)
{
    $ret = "";
    $cwd = getcwd();
    if (chdir($dir)){
        $files = glob("*");
        rsort($files);
        foreach ($files as $k=>$v){
            if ($k == 0){
                $ret = file_get_contents($v);
            }
            if ($k >= $n){
                unlink($v);
            }
        }
        chdir($cwd);
    }
    return $ret;
}


