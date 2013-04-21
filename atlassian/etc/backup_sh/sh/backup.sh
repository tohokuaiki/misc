#!/usr/bin/php
<?php
$server = parse_ini_file(dirname(dirname(__FILE__)).'/server.ini', true);
$backup_dir = dirname(dirname(__FILE__)).'/data';
$backup_days = 7;


$today = date('Ymd');

require_once 'DB.php';
foreach ($server as $application => $clients){
    foreach ($clients as $client=>$data_dir){
        $save_dir = sprintf("%s/%s/%s/%s",
                            $backup_dir, $application, $client, $today);
        if (!file_exists($save_dir)){
            mkdir($save_dir, 0755, true);
        }
        // mysql
        if ($dsn = getAtlassianDSN($application, $data_dir)){
            $cmd = sprintf('mysqldump --default-character-set=utf8 -h %s -u %s -p%s %s > %s/mysql.sql',
                           $dsn['server'],
                           $dsn['username'],
                           $dsn['password'],
                           $dsn['database'],
                           $save_dir
                           );
            //echo $cmd ."\n";
            system($cmd);
        }
        // data_dir
        $cmd = sprintf('cp -frp %s/* %s/',
                       $data_dir, $save_dir);
        //echo $cmd ."\n";
        system($cmd);
        // zip
        $cmd = sprintf('zip -rqm %s.zip %s', 
                       $save_dir, $save_dir);
        //echo $cmd ."\n";
        system($cmd);
        // remove old backupfiles
        $cwd = getcwd();
        chdir(dirname($save_dir));
        $files = glob('*.zip');
        rsort($files);
        foreach ($files as $k=>$v){
            if ($k >= $backup_days){
                $cmd = sprintf('rm -f %s', $v);
                //echo $cmd ."\n";
                system($cmd);
            }
        }
        chdir($cwd);
    }
}




/**
 * @brief 
 * @param 
 * @retval
 */
function getAtlassianDSN($application, $data_dir)
{
    $ret = array(
        'server' => '', 'database' => '', 'username' => '', 'password' => '',
        );
    
    $dom = new DOMDocument('1.0', 'utf-8');
    
    try  {
        switch ($application)
        {
          case "confluence":
            $xml = $data_dir .'/confluence.cfg.xml';
            if ($dom->loadXML(file_get_contents($xml))) {
                foreach ($dom->getElementsByTagName('property') as $property){
                    switch ($property->getAttribute('name')){
                      case 'hibernate.connection.url':
                        $dsn = $property->textContent;
                        $dsn = DB::parseDSN($dsn);
                        $ret['database'] = $dsn['database'];
                        $ret['server']   = $dsn['hostspec'];
                        break;
                      case 'hibernate.connection.username':
                        $ret['username'] = $property->textContent;
                        break;
                      case 'hibernate.connection.password':
                        $ret['password'] = $property->textContent;
                        break;
                    }
                }
            }
            break;
          case "jira":
            $xml = $data_dir.'/dbconfig.xml';
            if ($dom->loadXML(file_get_contents($xml))){
                foreach ($dom->getElementsByTagName('jdbc-datasource')->item(0)->childNodes as $property){
                    switch ($property->tagName){
                      case 'url':
                        $dsn = DB::parseDSN($property->textContent);
                        $ret['database'] = $dsn['database'];
                        $ret['server']   = $dsn['hostspec'];
                        break;
                      case 'username':
                        $ret['username'] = $property->textContent;
                        break;
                      case 'password':
                        $ret['password'] = $property->textContent;
                        break;
                    }
                }
            }
            break;
        }
    } catch (Exception $e){
        echo $e->getMessage();
        return false;
    }
    
    return $ret;
}
