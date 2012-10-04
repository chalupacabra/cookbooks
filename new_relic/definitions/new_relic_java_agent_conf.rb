define :new_relic_java_agent_config do
  node['new_relic']['config']['file_path'] = params[:name]

  jar_path = File.join(File.dirname(node['new_relic']['config']['file_path']),
                       'newrelic.jar')

  cookbook_file jar_path do
    backup false
    source 'newrelic.jar'
    cookbook 'new_relic'
  end

  template node['new_relic']['config']['file_path'] do
    backup false
    source 'java_agent_newrelic.yml.erb'
    variables :config_var => node['new_relic']['config']
  end
end
