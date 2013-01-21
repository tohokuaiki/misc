<?php
if (!class_exists("COM"))
    exit("COM object is not valid.");

$wmp = new COM("WMPlayer.OCX");
$cdroms = $wmp->cdromCollection;
for ($i=0; $i<$cdroms->count; $i++){
    $cdroms->item($i)->eject();
 }
