#!/usr/bin/php
<?php
require_once 'vendor/autoload.php';
use Saklient\Cloud\API as API;
use GetOpt\GetOpt;
use GetOpt\Option;
use GetOpt\Command;

// set command options
$getOpt = new GetOpt();
$getOpt->addOptions([
    Option::create('h', 'help',   GetOpt::NO_ARGUMENT)->setDescription('Show this help and quit'),
    Option::create('s', 'server', GetOpt::REQUIRED_ARGUMENT)->setDescription('サーバー名の指定'),
    Option::create('t', 'token',  GetOpt::REQUIRED_ARGUMENT)->setDescription('さくらクラウドのTokenファイル'),
    ])->addCommands([
        Command::create('status', 'Server::status')->setDescription('サーバー状態を表示'),
        Command::create('boot',   'Server::up')->setDescription('サーバーを起動'),
        Command::create('stop',   'Server::stop')->setDescription('サーバーをシャットダウン'),
        Command::create('plan',   'Server::plan')->setDescription('サーバープランを変更')
          ->addOptions([
              Option::create('m', 'memory', GetOpt::REQUIRED_ARGUMENT)->setDescription('変更するメモリのサイズをギガ単位で指定'),
              Option::create('c', 'cpu',    GetOpt::REQUIRED_ARGUMENT)->setDescription('変更するCUPのコア数を指定'),
              ]),
        ]);

// execute
$server_name = $command_name = $cpu = $mem = '';
try {
    $getOpt->process();
    if ($getOpt->getOption('help')){
        echo PHP_EOL . $getOpt->getHelpText();
        exit;
    }
    if (!$command = $getOpt->getCommand()){
        throw new Exception('コマンドを指定してください。');
    }
    $command_name = $command->getName();
    $server_name  = $getOpt->getOption('s');
    if (!$server_name) {
        throw new Exception('サーバー名を指定してください。');
    }
    $token_file  = $getOpt->getOption('t');
    if (!$token_file) {
        throw new Exception('Tokenファイル名を指定してください。');
    }
    $ini = array_merge([
        'zone' => '', 'token' => '', 'token_secret' => '', 
    ], @parse_ini_file($token_file));
    
    // main
    $api = API::authorize($ini['token'], $ini['token_secret'], $ini['zone']);
    $server = $api->server->withNameLike($server_name)->find();
    if (count($server) !== 1){
        throw new Exception($server_name . 'の設定は1つのサーバを指しません。');
    }
    $server = current($server);
    switch ($command_name){
      case 'boot' :
        if ($server->isUp()){
            throw new Exception($server_name . "サーバーは既に起動中です。");
        }
        else {
            echo "サーバーを起動します... => \t";
            $server->boot();
            printf("%s\n", $server->isUp() ? 'SUCCESS' : 'FAILED');
        }
        break;
      case 'stop':
        if ($server->isDown()){
            throw new Exception($server_name . "サーバーは既に停止中です。");
        }
        else {
            echo "サーバーを停止します... => \t";
            $server->stop();
            printf("%s\n", $server->isUp() ? 'FAILED' : 'SUCCESS');
        }
        break;
      case 'plan':
        if ($server->isUp()){
            throw new Exception($server_name . "サーバーの起動中はプラン変更できません。");   
        }
        else {
            echo "サーバーのCPUとメモリのプランを変更します。...=> \t";
            $cpu =  $getOpt->getOption('c');
            $mem =  $getOpt->getOption('m');
            $plan = $api->product->server->getBySpec($cpu, $mem);
            if (!$plan){
                throw new Exception($server_name . "指定したCPUとメモリの組み合わせのプランはありません。");   
            }
            $server->changePlan($plan);
        }
        break;
    }
    
    // サーバー状態をプリント
    printf("[Server]\n\tName: %s\n\tDescription: %s\n\tStatus: %s\n",
           $server->name, $server->description, $server->isUp() ? 'Up' : 'Down');
    echo "\n";
    echo "[Plan]\n";
    foreach ($server->plan->dump() as $k=>$v){
        printf("\t%s: %s\n", $k, $v);
    }
    exit(0);
} catch (Exception $exception) {
    file_put_contents('php://stderr', $exception->getMessage() . PHP_EOL);
    exit(1);
}
