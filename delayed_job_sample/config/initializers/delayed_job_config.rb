Delayed::Worker.destroy_failed_jobs = false # 失敗したジョブをDBから削除しない=false
Delayed::Worker.sleep_delay = 60 # 実行ジョブがない場合に次回実行までのSleep時間（秒）
Delayed::Worker.max_attempts = 3 # リトライ回数
Delayed::Worker.max_run_time = 5.minutes # 最大実行時間
