#!/usr/bin/php
<?php
$cwd = dirname(__FILE__);
chdir($cwd);
$ini = dirname(__FILE__). '/site_backup.ini';
$ini_stat = substr(sprintf('%o', fileperms($ini)), -4);
if ($ini_stat !== "0600"){
    printf("ini file[%s] permission is not 0600.\n",
           $ini);
    exit;
}

$site_info = parse_ini_file($ini, true);
$config = $site_info['config'];

$today = date('Ymd');
$log_dir = dirname(__FILE__)."/log/site_backup";

$descriptorspec = array(
    0 => array("pipe", "r"),
    1 => array("file", $log_dir. "/process.".$today.".log", "a"),
    2 => array("file", $log_dir. "/error.".$today.".log", "a"),
    );

foreach ($descriptorspec as $desc){
    if ($desc[0] == "file"){
        $dir = dirname($desc[1]);
        if (!is_dir($dir)){
            if (!mkdir($dir, 0755, true)){
                printf("could not create log dir [%s]\n", $dir);
                exit;
            }
        }
        if ($fp = fopen($desc[1], $desc[2])){
            fputs($fp, sprintf("[%s]\n", date('Y/m/d H:i:s')));
            fclose($fp);
        }
    }
}


foreach ($site_info as $host => $ftpinfo){
    if (!$host || !isset($ftpinfo['user'])){
        continue;
    }

    printf("[%s] mirror start\n", $host);
    $local_backup_path = sprintf("%s/site/%s/%s",
                                 dirname(__FILE__),
                                 $host,
                                 date('l'));

    if (!file_exists($local_backup_path) && !is_dir($local_backup_path)){
        echo "mkdir -p $local_backup_path\n";
        if (!mkdir($local_backup_path, 0755, true)){
            printf("backup path [%s] create failed.\n",
                   $local_backup_path);
            continue;
        }
    }


    $ftpinfo['local_backup_path'] = $local_backup_path;
    $zip_file = $local_backup_path .".zip";
    chdir(dirname($zip_file));
    if (file_exists($zip_file)){
        system('unzip -q -o '. basename($zip_file));
        unlink($zip_file);
    }
    chdir($cwd);
    ftp_backup($descriptorspec, $host, $ftpinfo);
    chdir(dirname($zip_file));
    $zip_cmd = sprintf('zip -q -m -r %s %s',
                       $zip_file, basename($local_backup_path));
//    var_dump($local_backup_path, $zip_cmd, dirname($zip_file));
    system($zip_cmd);
}
if (date("w") == 1){
    sendStoredStatus($config);
}

/**
 * @brief
 * @param
 * @return
 */
function ftp_backup($descriptorspec, $host, $ftpinfo)
{
    extract($ftpinfo);
    if (!$host || !$user || !$pass || !$host_document_root || !$local_backup_path){
        printf("[%s] params is not valid.\n", $host);
        return false;
    }

    if (!is_dir($local_backup_path) && !is_writable($local_backup_path)){
        printf("%s is not writable.\n", $local_backup_path);
        return false;
    }

    $process = proc_open('lftp', $descriptorspec, $pipes);

    if (is_resource($process)){
        fputs($pipes[0],  sprintf("open -u %s,%s %s\n",
                                  $user, $pass, $host));
        // fputs($pipes[0], "ls\n");
        $exclude_list = "";
        if (isset($ftpinfo['exclude'])){
            foreach (explode(",", $ftpinfo['exclude']) as $e){
                $exclude_list .= " -X ".$e;
            }
        }
        fputs($pipes[0], sprintf("mirror -n -p --delete --only-newer --verbose %s %s %s\n",
                                 $exclude_list, $host_document_root, $local_backup_path));

        foreach ($pipes as $p){
            fclose($p);
        }

        $return_value = proc_close($process);
        echo "command returned $return_value\n";
    }
}




/**
 * @brief
 * @param
 * @retval
 */
function sendStoredStatus($config)
{
    $text = "サイトバックアップの一覧\n";

    $local_backup_path = sprintf("%s/site",
                                 dirname(__FILE__));

    $file = getFileList($local_backup_path);

    $dirs = $file['dir'];
    sort($dirs);
    foreach ($dirs as $dir){
        if (strpos($dir, '/')) continue;
        $text .= sprintf("\n[%s]\n", trim(str_replace($local_backup_path, '', $dir), '/'));
        $files = array();
        foreach ($file['file'] as $f){
            $pos = strpos($f, $dir);
            if ($pos !== false){
                $f_stat = stat($f);
                $files[$f_stat['mtime']] = array(
                    'size'  => $f_stat['size'],
                    'mtime' => date('Y/m/d H:i:s', $f_stat['mtime']),
                    'name'  => str_replace($dir.'/', '', $f),
                    );
            }
        }
        ksort($files);
        foreach ($files as $f){
            $text .= sprintf("%s\t% -16s \t% -12s\n",
                             $f['mtime'],
                             $f['name'],
                             number_format($f['size']));
        }
    }

    $header  = sprintf("From: %s\n", $config['from']);
    $subject = sprintf('バックアップファイル一覧(%s)', $config['server_name']);
//    $subject = mb_encode_mimeheader($subject, "ISO-2022-JP", 'Q', "\n");
    mb_language("japanese");
    mb_internal_encoding("UTF-8");
    mb_send_mail($config['checkmail'], $subject, $text, $header);
}



/**
 * @brief
 * @param
 * @retval
 */
function getFileList($dir, $list=array('dir'=> array(), 'file' => array()))
{
    if (is_dir($dir) == false) {
        return $list;
    }

    $dh = opendir($dir);

    if ($dh) {
        while (($file = readdir($dh)) !== false) {
            if ($file == '.' || $file == '..'){
                continue;
            }
            else if (is_dir("$dir/$file")) {
                $list = getFileList("$dir/$file", $list);
                $list['dir'][] = "$dir/$file";
            }
            else {
                $list['file'][] = "$dir/$file";
            }
        }
    }
    closedir($dh);
    return $list;
}
