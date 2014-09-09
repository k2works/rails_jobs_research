delayed_job_app_service = node['my_app']

execute "init.d経由でRVMを使えるようにする" do
  command "rvm alias create #{node['my_app']} ruby-#{node['rvm']['app_version']}@#{node['rvm']['app_gemset']}"
end

template "/etc/init.d/#{delayed_job_app_service}" do
  source "delayed_job_service.erb"
  owner 'root'
  group 'root'
  mode "0755"
end

service "#{delayed_job_app_service}" do
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
end
