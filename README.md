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

# 構成
+ [Resque](#1)
+ [Delayed](#2)

# 詳細
## <a name="1">Resque</a>
_resque_sample_
### 初期設定
### Controllerの作成
### ResqueWorker作成
```
QUEUE=resque_sample rake environment resque:work

# すべてのworkerを対象としたい場合は*を指定
QUEUE=* rake environment resque:work
```
### 確認
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

# 参照
+ [Resque](https://github.com/resque/resque/tree/1-x-stable)
+ [Hello World Resque (Railsにresqueを導入する)](http://qiita.com/hilotter/items/fc432c33f5a012b87dca)
+ [Delayed::Job](https://github.com/collectiveidea/delayed_job)
