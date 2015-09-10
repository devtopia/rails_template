APP_PATH = File.expand_path('../../', __FILE__)
worker_processes 5
working_directory APP_PATH
listen APP_PATH + '/tmp/sockets/unicorn.sock'
pid APP_PATH + '/tmp/pids/unicorn.pid'
stderr_path APP_PATH + '/log/unicorn.stderr.log'
stdout_path APP_PATH + '/log/unicorn.stdout.log'
preload_app true
before_fork do |server, worker|
  defined?(ActiveRecord::Base) and ActiveRecord::Base.connection.disconnect!
  if defined?(Resque)
    Resque.redis.quit
    Rails.logger.info('Disconnected from Redis')
  end
  old_pid = "#{server.config[:pid]}.oldbin"
  if old_pid != server.pid
    begin
      sig = (worker.nr + 1) >= server.worker_processes ? :QUIT : :TTOU
      Process.kill(sig, File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
    end
  end
end
after_fork do |server, worker|
  defined?(ActiveRecord::Base) and ActiveRecord::Base.establish_connection
  if defined?(Resque)
    Resque.redis = Settings.redis_url
    Resque.redis.namespace = Settings.redis_namespace
    Rails.logger.info('Connected to Redis')
  end
  if defined?(ActiveSupport::Cache::DalliStore) && Rails.cache.is_a?(ActiveSupport::Cache::DalliStore)
    Rails.cache.reset
    ObjectSpace.each_object(ActionDispatch::Session::DalliStore) { |obj| obj.reset }
  end
end
