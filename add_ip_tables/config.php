<?php
define('ADD_IP_LIST_FILE', dirname(__FILE__).'/.ht_add_ip_list');
define('IP_VALID_TERM', 7200); // 2hours




/**
 * @brief 登録されているIPリストを取得して配列で返す
 * @param 
 * @return Array
 */
function  get_registered_ip_list()
{
    if (!file_exists(ADD_IP_LIST_FILE)){
        touch(ADD_IP_LIST_FILE);
        chmod(0666, ADD_IP_LIST_FILE);
    }
    
    $list = array();
    foreach (file(ADD_IP_LIST_FILE) as $line){
        $line = trim($line);
        $cell = explode("\t", $line);
        $list[] = array(
            'time' => $cell[0],
            'ip'   => $cell[1],
            );
    }
    
    return $list;
}

/**
 * @brief IPリストで無効な時間のものをFilter
 * @param Array
 * @return Array
 */
function check_valid_term($list)
{
    $now = time();
    
    $nlist = array();
    foreach ($list as $l){
        if ($l['time'] + IP_VALID_TERM > $now){
            $nlist[] = $l;
        }
    }
    
    return $nlist;
}

/**
 * @brief リスト配列に新しいIPを加える。既存であれば、時刻を今にする
 * @param Array
 * @param String
 * @return Array
 */
function add_new_ip($list, $add_ip = null)
{
    $now = time();

    if (is_null($add_ip)){
        $add_ip = $_SERVER['REMOTE_ADDR'];
    }
    
    $key = false;
    foreach ($list as $k=>$v){
        if ($v['ip'] === $add_ip){
            $key = $k;
        }
    }
    if ($key === false){
        $list[] = array(
            'time' => $now,
            'ip'   => $add_ip,
            );
    }
    else {
        $list[$key] = array(
            'time' => $now,
            'ip'   => $add_ip,
            );
    }
    
    return $list;
}


/**
 * @brief ファイルにリストを保存する
 * @param Array
 * @return boolean
 */
function save_ip_list($list)
{
    $list_str = "";
    
    foreach ($list as $l){
        $list_str .= sprintf("%s\t%s\n", 
                             $l['time'], $l['ip']);
    }

    return false !== file_put_contents(ADD_IP_LIST_FILE, $list_str);
}
