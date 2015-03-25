#!/usr/bin/php
<?php
$arg = $_SERVER['argv']; 
if (count($arg) <= 1){
    error_log('specify commit tag.');
    exit;
}

$gitcmd = sprintf('git diff --name-status %s', $arg[1]);
ob_start();
passthru($gitcmd, $ret);
$buff = ob_get_clean();

if ($ret !== 0){
    exit($buff);
}


$basedir = getSTDIN("Please specify copy target directory.");
if (file_exists($basedir))
{
    if (is_file($basedir)){
        error_log($basedir . " >> file exists\n");
        exit;
    }
    $ret = "";
    do {
        $ret = getSTDIN(sprintf("%s is existing directory. Overwrite O.K? [Overwrite/Cancel/Remove]",
                                $basedir));
        $ret = strtolower($ret);
        if (strncasecmp($ret, "c", 1) === 0){
            exit;
        }
        if (strncasecmp($ret, "r", 1) === 0){
            $confirm = getSTDIN(sprintf("Remove all files about %s. Really?[ok/Cancel]", $basedir));
            if (strncasecmp($confirm, "o", 1) === 0){
                system("rm -fr ".$basedir);
            }
        } 
    } while(!in_array($ret, array('o', 'c', 'r')));
}
if (!is_dir($basedir)){
     mkdir_p($basedir);
}

$basedir = rtrim($basedir, '/');

$files = explode(PHP_EOL, $buff);
$delete = array();
foreach ($files as $file){
    $file = trim($file);
    if (!$file){
        continue;
    }
    $file = explode("\t", $file);
    $status = $file[0];
    $file   = $file[1];
    if (strcasecmp($status, 'd') === 0){
        $delete[] = "rm -f ".$file;
        continue;
    }
    if (file_exists($file)){
        $dir = $basedir."/".dirname($file);
        if (!is_dir($dir)){
            mkdir_p($dir);
        }
        copy($file, $basedir."/".$file);
        printf("copy %s\n", $file);
    }
}
if ($delete){
    file_put_contents($basedir."/delete_file.sh", implode("\n", $delete));
}
exit();


function getSTDIN($msg)
{
    printf(">> %s\n",  $msg);
    $line = "";
    do {
        $line = trim(fgets(STDIN));
    } while (!$line);
    
    return $line;
}


function mkdir_p($dir)
{
    if (file_exists($dir)) {
        return is_dir($dir);
    }

    $parent = dirname($dir);
    if ($dir === $parent) {
        return true;
    }

    if (is_dir($parent) === false) {
        if (mkdir_p($parent) === false) {
            return false;
        }
    }
    
    return mkdir($dir);
}
