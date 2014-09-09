Rails ジョブ調査
===
# 目的
Railsでのジョブ実行環境の調査及び評価

# 前提
| ソフトウェア     | バージョン    | 備考         |
|:---------------|:-------------|:------------|
| OS X           |10.8.5        |             |
| ruby      　　　|2.1.1        |             |
| rails     　　　|4.1.1        |             |
| redis     　　　|2.8.9        |             |
| resque    　　　|1.5.1        |             |
| delayed_job 　 |4.0.3        |             |
| delayed_job_active_record 　 |4.0.2        |             |
| daemons 　 |1.1.9        |             |


# 構成
+ [Resque](#1)
+ [Delayed](#2)
+ [デプロイ](#3)
+ [Resque vs DelayedJob](#4)

# 詳細
## <a name="1">Resque</a>
### 初期設定
```bash
$ rails new resque_sample
```
gem追加
```ruby
gem 'resque'
```
```
$ bundle install --path=vendor/bundler
```
_resque_sample/config/initializers/resque.rb_
```
Resque.redis = 'localhost:6379'
Resque.redis.namespace = "resque:resque_sample:#{Rails.env}" # アプリ毎に異なるnamespaceを定義しておく
```
### Controllerの作成
```bash
$ rails g controller home
```
### ResqueWorker作成
```bash
$ mkdir app/workers
$ rails g task resque
```
```
QUEUE=resque_sample rake environment resque:work

# すべてのworkerを対象としたい場合は*を指定
QUEUE=* rake environment resque:work
```
### 確認
ブラウザから

http://localhost:3000/hello/world  
http://localhost:3000/hello/resque  
にアクセスして
```bash
$ tail -f log/resque.log
```
### Daemon化してみる
起動
```bash
$ chmod 755 bin/resque_worker
$ RAILS_ENV=development ./bin/resque_worker start
```
### フロントエンド
_resque_sample/config/routes.rb_を編集
```ruby
require 'resque/server'
Rails.application.routes.draw do
  mount Resque::Server.new, :at => "/resque"
  get "hello/:message" => 'home#hello'
・・・
```
_http://localhost:3000/resque/_にアクセス
## <a name="2">Delayed</a>
### Gemfile作成
```
$ rails new delayed_job_sample
$ cd delayed_job_sample
```
_delayed_job_sample/Gemfile_
```ruby
gem "delayed_job"
gem "delayed_job_active_record"

# デプロイ先でデーモンとして動かすのに必要
gem "daemons"
```
### インストールとマイグレーション
```
$ bundle
$ bundle exec rails generate delayed_job:active_record
bundle exec rake db:migrate
```
### 非同期処理を実装
```
$ rails g controller home
$ rails g model hello
$ rake db:migrate
```
処理を実装後`rails s`でサーバーを起動させたら以下にアクセスする。
_http://localhost:3000/hello/hoge_

Rakeタスク実行
```
$ bundle exec rake jobs:work
[Worker(host:MacBook-Air.local pid:13414)] Starting job worker
[Worker(host:MacBook-Air.local pid:13414)] Job Class#say_hello (id=1) RUNNING
[Worker(host:MacBook-Air.local pid:13414)] Job Class#say_hello (id=1) COMPLETED after 5.0079
[Worker(host:MacBook-Air.local pid:13414)] 1 jobs processed at 0.1984 j/s, 0 failed
```
ログを確認
```
$ cat log/delay.log
# Logfile created on 2014-09-08 13:47:25 +0900 by logger.rb/44203
I, [2014-09-08T13:50:12.464809 #13414]  INFO -- : Hello hoge
```
### Daemon化してみる
_delayed_job_sample/tools_
```bash
#!/bin/bash
bundle exec ./bin/delayed_job $1
```
デーモン実行
```bash
$ RAILS_ENV=development tools/delayed_job.sh start
```
ログ
```bash
$ tail -f log/delayed_job.log
# Logfile created on 2014-09-08 14:17:35 +0900 by logger.rb/44203
I, [2014-09-08T14:17:35.535434 #13911]  INFO -- : 2014-09-08T14:17:35+0900: [Worker(delayed_job host:MacBook-Air.local pid:13911)] Starting job worker
I, [2014-09-08T14:20:10.561905 #13967]  INFO -- : 2014-09-08T14:20:10+0900: [Worker(delayed_job host:MacBook-Air.local pid:13967)] Starting job worker
I, [2014-09-08T14:21:20.309367 #13994]  INFO -- : 2014-09-08T14:21:20+0900: [Worker(delayed_job host:MacBook-Air.local pid:13994)] Starting job worker
I, [2014-09-08T14:22:50.192659 #14066]  INFO -- : 2014-09-08T14:22:50+0900: [Worker(delayed_job host:MacBook-Air.local pid:14066)] Starting job worker
I, [2014-09-08T14:23:50.319379 #14066]  INFO -- : 2014-09-08T14:23:50+0900: [Worker(delayed_job host:MacBook-Air.local pid:14066)] Job Class#say_hello (id=2) RUNNING
I, [2014-09-08T14:23:55.329217 #14066]  INFO -- : 2014-09-08T14:23:55+0900: [Worker(delayed_job host:MacBook-Air.local pid:14066)] Job Class#say_hello (id=2) COMPLETED after 5.0092
I, [2014-09-08T14:23:55.330545 #14066]  INFO -- : 2014-09-08T14:23:55+0900: [Worker(delayed_job host:MacBook-Air.local pid:14066)] 1 jobs processed at 0.1983 j/s, 0 failed
```
### 設定ファイル
_delayed_job_sample/config/initializers/delayed_job_config.rb_
```ruby
Delayed::Worker.destroy_failed_jobs = false # 失敗したジョブをDBから削除しない=false
Delayed::Worker.sleep_delay = 60 # 実行ジョブがない場合に次回実行までのSleep時間（秒）
Delayed::Worker.max_attempts = 3 # リトライ回数
Delayed::Worker.max_run_time = 5.minutes # 最大実行時間
```

## <a name="3">デプロイ</a>
### デプロイ先仮想マシン準備
```bash
$ cd cookbooks/delayed_job_sample
$ vagrant up --provision
```

### Capistranoインストール
_delayed_job_sample/Gemfile_
```ruby
gem "capistrano"
gem "capistrano-ext"
```
```
$ bundle install
```
```
$ cap install
```
### デプロイ用ファイル編集
_delayed_job_sample/config/deploy.rb_  
_delayed_job_sample/config/deploy/production.rb_  
_delayed_job_sample/Capfile_

### デプロイ実行
```bash
$ cap production deploy
$ ssh vagrant@192.168.33.10
vagrant@192.168.33.10's password:vagrant  
$ cd delayed_job_sample/
$ rm -rf vendor
$ bundle
```
### Production環境セットアップ
```
$ bundle exec rake secret
$ export SECRET_KEY_BASE=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
$ sudo chown -R vagrant db/
$ RAILS_ENV=production bundle exec rake db:migrate
$ RAILS_ENV=production bundle exec rails s &
```

### delayed_jobのサービス化
_cookbooks/delayed_job_sample/attributes/default.rb_  
_cookbooks/delayed_job_sample/templates/default/delayed_job_service.erb_  
_cookbooks/delayed_job_sample/recipes/service_config.rb_  

サービスの実行&自動起動設定
```bash
$ sudo service delayed_job start
$ sudo update-rc.d delayed_job defaults
```

## <a name="4">Resque vs DelayedJob</a>

どのようにResqueとDelayJobを比べればよいか、そしてなぜ一方を選択するか？

+ Resqueは複数のキューをサポートしています。  
+ DelayedJobは洗練された優先付けができる。  
+ Resqueワーカーはメモリリークや膨張から立ち直るのが早い。  
+ DelayedJobワーカーはすごいシンプルで変更が容易。  
+ ResqueはRedisが必要。  
+ DelayedJobはActiveRecordが必要。  
+ ResqueはJSON Rubyオブジェクトをキューにすることが唯一できる。  
+ DelayedJobはRubyオブジェクトを引数にできる。  
+ ResqueにはSinatra製モニタリングアプリが含まれている。  
+ DelayedJobはインターフェースを自分で追加したらならRailsアプリケーションの中で検索することができる。  
+ もしRailsの開発していてすでにデータベースとActiveRecordを使っているなら。DelayJobはとても簡単にセットアップできます。GitHubは2億件のジョブに使っています。  

Resqueを選択する場合

+ 複数のキューを必要とする。  
+ 数値の優先順位を気にしなくてくてよくなる。  
+ 全てのRubyオブジェクト永続化する必要がなくなる。  
+ 潜在的に多くのキューを必要とする。  
+ 何が起こっているのか確認したい。  
+ 多くの失敗や混乱が想定される。  
+ Redisをセットアップできる。  
+ RAM上での短時間の実行ではない。

DelayedJobを選択する場合

+ 数値的に順位付けるのが好き。  
+ 毎日大量のジョブを実行しない。  
+ キューが小さくて早い。  
+ 失敗や混乱が少ない。  
+ なんでもすぐにキューに載せたい。  
+ Redisをセットアップしたくない。  

常にResqueがDelayedJobが優れているわけではない、だから自分のアプリケーションにとってベストな選択をしよう。

# 参照
+ [Resque](https://github.com/resque/resque/tree/1-x-stable)
+ [Hello World Resque (Railsにresqueを導入する)](http://qiita.com/hilotter/items/fc432c33f5a012b87dca)
+ [Delayed::Job](https://github.com/collectiveidea/delayed_job)
+ [【Rails 4】delayed_jobを使う](http://qiita.com/azusanakano/items/1d2629763f35b5466286)
+ [ghazel/daemons](https://github.com/ghazel/daemons)
+ [BestGems Pickup! 第6回 「daemons」](http://www.xmisao.com/2013/09/28/bestgems-pickup-daemons.html)
+ [Capistrano3 をファイル転送のためだけに使ってみる](http://isann.hatenablog.com/entry/2014/01/16/003850)
+ [Unicorn プロセスを自動起動させる init.d スクリプト用の Chef Recipe](http://easyramble.com/unicorn-initd-chef-recipe.html)
+ [Using RVM and Ruby-based services that start via init.d or upstart](http://rvm.io/integration/init-d)
+ [Debian(Ubuntu)で サービスの起動、停止を管理するツールを調べてみた(chkconfigのかわりになるもの)](http://server-setting.info/debian/debian-like-chkconfig.html)
