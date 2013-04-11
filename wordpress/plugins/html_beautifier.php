<?php
/**
Plugin Name: HTML Beautifier
Plugin URI: http://www.junoe.jp
Description: 出力時にHTMLをキレイにインデントして出力
Version: 1.0
Author: ITOH Takashi@Junoe
Author URI: http://d.hatena.ne.jp/tohokuaiki
License: GPLv2 or later
*/
if (class_exists('tidy')){
    ob_start('junoe_html_beautifier');
}


/**
 * @brief Beautify HTML
 * @param String HTML
 * @retval String beautified HTML
 */
function junoe_html_beautifier($html)
{
    $tidy = new tidy;

    $config = array(
        'indent' => true,
        'wrap'   => 1000,
        );
    $tidy->parseString($html, $config, 'utf8');
    $tidy->cleanRepair();
    return $tidy->html()->value;
    
}
