<?php
/**
 * @package Nakano property banner
 * @version 1.0
 */
/*
Plugin Name: Nakano property banner
Plugin URI: http://d.hatena.ne.jp/tohokuaiki
Description: あるページを閲覧した回数によって表示するバナーを変える。バナー表示箇所はテンプレートなら<?php echo nknprop_banner("propA");?>とし、記事内ショートコードなら[nknprop_banner_tag type="propA"]とする。バナーの定義はプラグインファイルに$nbp_setting変数で直書き
Author: ITOH Takashi
Version: 1.0
Author URI: http://d.hatena.ne.jp/tohokuaiki
*/
$nbp_setting = array(
    'propA' => array(
        'target_post_id' => 9,
        'counter' => array(
            2 => array(
                /* propAというバナーは、ID=9の記事を2回まで見た場合は下記のスペック(上からリンク先、画像、新しいタブで開く(or false))でバナーを表示する。 */
                'http://nakanopropertymalaysia.com/?post_type=fudo&p=6111',
                'http://nakanopropertymalaysia.com/images/2013/07/2013-07-19_10-22-45_A41.jpg',
                true),
            3 => array(
                /* propAというバナーは、ID=9の記事を3回まで見た場合は下記のスペック(上からリンク先、画像、新しいタブで開く(or false))でバナーを表示する。 */
                'http://nakanopropertymalaysia.com/?post_type=fudo&p=4293',
                'http://nakanopropertymalaysia.com/images/2013/01/2013-01-15-13.02.38-293x220.jpg',
                true),
            4 => array(
                /* propAというバナーは、ID=9の記事を4回まで見た場合は下記のスペック(上からリンク先、画像、新しいタブで開く(or false))でバナーを表示する。
                   4回以上は定義がないので、終わり
                 */
                'http://nakanopropertymalaysia.com/?post_type=fudo&p=6111',
                'http://nakanopropertymalaysia.com/images/2013/01/2012-12-11-19.51.36-293x220.jpg',
                true),
            ),
        ),
    );

add_action('get_header', 'nknprop_banner_set_read_cookie_header');
remove_action('wp_head', 'adjacent_posts_rel_link_wp_head' );

define('NKNPROP_BANNER_COOKIE_NAME', 'nknprop_banner_c');
define('NKNPROP_BANNER_COOKIE_EXPIRE', 365);

function nknprop_banner_set_read_cookie_header()
{
    global $post;
    
    if (!is_object($post) || !$post->ID){
        return ;
    }
    $post_id = $post->ID;
    
    $expire = time() + NKNPROP_BANNER_COOKIE_EXPIRE * 86400; 
    $cookie_array  = nknprop_banner_parse_cookie();
    
    if (isset($cookie_array[$post_id])){
        $cookie_array[$post_id]++;
    } else {
        $cookie_array[$post_id] = 1;
    }
    
    $cookie_array2 = array();
    foreach ($cookie_array as $post_id => $count){
        $cookie_array2[] = sprintf('%d:%d', $post_id, $count);
    }
//    var_dump($cookie_array2); 
    setcookie(NKNPROP_BANNER_COOKIE_NAME, implode('|', $cookie_array2), $expire, COOKIEPATH);
}


function nknprop_banner_parse_cookie()
{
    $cookie = isset($_COOKIE[NKNPROP_BANNER_COOKIE_NAME]) ? $_COOKIE[NKNPROP_BANNER_COOKIE_NAME] : "";
    
    $cookie = explode("|", $cookie);
    $cookie_array = array();
    foreach ($cookie as $pair){
        $cookie_p = explode(":", $pair);
        if (count($cookie_p) == 2){
            $cookie_array[$cookie_p[0]] = $cookie_p[1];
        }
    }
    
    return $cookie_array;
}


function nknprop_banner($type, $output = true)
{
    global $nbp_setting;
    
    if (!isset($nbp_setting[$type])){
        return "";
    }
    
    $target_post_id = $nbp_setting[$type]['target_post_id'];
    
    $cookie = nknprop_banner_parse_cookie();
    
    $count = isset($cookie[$target_post_id]) ? $cookie[$target_post_id] : 0;
    
    $ret = "";
    $target_prop = null;
    foreach ($nbp_setting[$type]['counter'] as $c_count => $prop){
        if ($c_count > $count){
            $target_prop = $prop;
            break;
        }
    }
    
    if ($target_prop){
        $ret = sprintf('<a href="%s" target="_%s" class="nknprop_banner"><img src="%s"></a>',
                       $target_prop[0], $target_prop[2] ? "blank" : "self", $target_prop[1]);
    }

    
    if ($output){
        echo $ret;
        return "";
    }
    else {
        return $ret;
    }
}

function nknprop_banner_tag($atts) {
    if (isset($atts["type"])){
        return nknprop_banner($atts["type"], false);
    }
    return "";
}
add_shortcode('nknprop_banner_tag', 'nknprop_banner_tag');
