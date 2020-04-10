# 使い方
## トークンファイルを用意
token.iniとかで保存。中にはこんな感じで3つパラメータ設定。
```
zone=is1b
;; tk1a => Tokyo1
;; is1a => Ishikari1
;; is1b => Ishikari2
;; tk1v => Sandbox
token=xxxxxxxxxxxxxxxx
token_secret=***********************
```
## コマンド実行
```
$ ./sakura_api.sh -h
```
でだいたいわかるけど。

### 起動
```
$ ./sakura_api.sh boot -s api_test_server -t token.ini
```
-sオプションで自分のさくらクラウドのサーバー名を指定、-t オプションでさっき作ったTokenファイルを指定。

### 状態確認
```
$ ./sakura_api.sh status -s api_test_server -t token.ini
```
### 停止
```
$ ./sakura_api.sh stop -s api_test_server -t token.ini
```

### プランを変更
CPU1コア、メモリ2Gに変更
```
$ ./sakura_api.sh plan -s api_test_server -t token.ini -m 2 -c 1
```
