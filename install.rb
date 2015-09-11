# encoding: UTF-8
require 'bundler'

puts "このテンプレートを利用する前に下記の事項をご確認ください。"
puts "新しいアプリケーションを生成するとき、下記のようなコマンドで実行しましたか？"
puts "rails new app_name -T -d database_name -m temp/install.rb --skip-bundle --skip-turbolinks"
puts "-Tオプションでminitestを生成しないようにします。"
puts "-dオプションでデータベースの種類を決めます。"
puts "-mオプションでテンプレートを指定します。"
puts "このテンプレートを利用する場合は、--skip-bundleオプションを入れてください。"
puts "turbolinksを利用しない場合は、--skip-turbolinksオプションを入れてください。"
puts "もし設定が間違ったら、やり直してください。"
unless yes?('設定は正しいですか？(yes/no)')
  puts "設定をやり直し、もう一度実行してください。"
  puts "設置は終了されます。"
  exit
end

# アプリ名の取得
@app_name = app_name

# sources
# src_path = [File.expand_path(File.dirname(__FILE__)), '/src'].join

# clean file
run 'rm README.rdoc'

# delete comment lines and blank lines to Gemfile
gsub_file 'Gemfile', /^#.*/, ''
gsub_file 'Gemfile', /^$\n/, ''

# add to Gemfile
insert_into_file 'Gemfile', %(
# Memcached Client
gem 'dalli'
# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem 'therubyracer', platforms: :ruby
# App Server
gem 'unicorn'
# Assets Log Cleaner
gem 'quiet_assets'
# Form Builders
gem 'simple_form'
# SQL Log Formatter
gem 'rails-flog'
# Pagenation
gem 'kaminari'
# Validator
gem 'date_validator'
gem 'email_validator'
# NewRelic
gem 'newrelic_rpm'
# Airbrake
gem 'airbrake'
# HTML Parser
gem 'nokogiri'
# Hash extensions
gem 'hashie'
# Settings
gem 'settingslogic'
# Cron Manage
gem 'whenever', require: false
# Email
gem 'mail-iso-2022-jp'
gem 'exception_notification'
# Send notifications to slack webhooks
gem 'slack-notifier'
# Decorator
gem 'active_decorator'
group :development do
  # A thin and fast web server
  gem 'thin'
  # Help to kill N+1 queries and unused eager loading
  gem 'bullet'
  # Use this gem to set up layout files for your choice of front-end framework
  gem 'rails_layout'
  # Better Errors replaces the standard Rails error page with a much better and more useful error page.
  gem 'better_errors'
  # Preview mail in the browser instead of sending
  gem 'letter_opener'
  gem 'letter_opener_web'
  # Generate Entity-Relationship Diagrams
  gem 'rails-erd'
  # Annotate ActiveRecord models
  gem 'annotate'
  # Bower on Rails
  gem 'bower-rails'
end
group :development, :test do
  # Pry & extensions
  gem 'pry-rails'
  gem 'pry-coolline'
  gem 'pry-byebug'
  gem 'rb-readline'
  # PryでのSQLの結果を綺麗に表示
  gem 'hirb'
  gem 'hirb-unicode'
  # pryの色付けをしてくれる
  gem 'awesome_print'
  # Rspec
  gem 'rspec-rails'
  # test fixture
  gem 'factory_girl_rails'
  # テスト環境のテーブルをきれいにする
  gem 'database_rewinder'
  # Time Mock
  gem 'timecop'
  # Shoulda matchers
  gem 'shoulda-matchers'
  # Test feature
  gem 'capybara'
  # Deploy
  gem 'capistrano', '~> 3.2.1'
  gem 'capistrano-rails'
  gem 'capistrano-rbenv'
  gem 'capistrano-bundler'
  gem 'capistrano3-unicorn'
end
), before: 'group :development, :test do'

# set config/application.rb
application  do
  %q{
    # Set timezone
    config.time_zone = 'Tokyo'
    config.active_record.default_timezone = :local
    # 日本語化
    I18n.enforce_available_locales = true
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :ja
    # generatorの設定
    config.generators do |g|
      g.orm :active_record
      g.test_framework  :rspec, :fixture => true
      g.fixture_replacement :factory_girl, :dir => "spec/factories"
      g.view_specs false
      g.controller_specs true
      g.routing_specs false
      g.helper_specs false
      g.request_specs false
      g.assets false
      g.helper false
    end
    # libファイルの自動読み込み
    config.autoload_paths += %W(#{config.root}/lib)
    config.autoload_paths += Dir["#{config.root}/lib/**/"]
  }
end

# set config/routes.rb
insert_into_file 'config/routes.rb', %(
  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end), after: 'Rails.application.routes.draw do'

# set config/environments/development.rb
environment 'config.action_mailer.delivery_method = :letter_opener_web', env: 'development'

# set env
run 'wget https://raw.githubusercontent.com/park-jh/templates/master/src/config/application.yml -P config/'

# set unicorn
run 'mkdir -p config/unicorn'
run 'wget https://raw.githubusercontent.com/park-jh/templates/master/src/config/unicorn/development.rb -P config/unicorn/'
run 'wget https://raw.githubusercontent.com/park-jh/templates/master/src/config/unicorn/production.rb -P config/unicorn/'

# set cache store
run 'wget https://raw.githubusercontent.com/park-jh/templates/master/src/config/initializers/cache_store.rb -P config/initializers/'
gsub_file 'config/initializers/cache_store.rb', /APPNAME/, @app_name

# set japanese locale
run 'wget https://raw.githubusercontent.com/park-jh/templates/master/src/config/locales/ja.yml -P config/locales/'

# set exception notification
run 'wget https://raw.githubusercontent.com/park-jh/templates/master/src/config/initializers/exception_notification.rb -P config/initializers/'
gsub_file 'config/initializers/exception_notification.rb', /APPNAME/, @app_name

# set settingslogic
run 'wget https://raw.githubusercontent.com/park-jh/templates/master/src/lib/settings.rb -P lib/'

# set database
db_name = ask('What is the database you are using? (postgresql/mysql/oracle/sqlserver)')
remove_file 'config/database.yml'
run "wget -O config/database.yml https://raw.githubusercontent.com/park-jh/templates/master/src/config/#{db_name}.yml"
gsub_file 'config/database.yml', /APPNAME/, @app_name
case db_name
when 'oracle'
  insert_into_file 'Gemfile', %(
gem 'activerecord-oracle_enhanced-adapter'
), after: "gem 'ruby-oci8'"
when 'sqlserver'
  insert_into_file 'Gemfile', %(
gem 'tiny_tds'
), before: "gem 'activerecord-sqlserver-adapter'"
end

# For Bullet (N+1 Problem)
insert_into_file 'config/environments/development.rb',%(
  # Bulletの設定
  config.after_initialize do
    Bullet.enable = true # Bulletプラグインを有効
    Bullet.alert = true # JavaScriptでの通知
    Bullet.bullet_logger = true # log/bullet.logへの出力
    Bullet.console = true # ブラウザのコンソールログに記録
    Bullet.rails_logger = true # Railsログに出力
  end), after: 'config.assets.debug = true'

@use_turbolinks = yes?('Use turbolinks? (yes/no)')
@use_redis = yes?('Use redis? (yes/no)')
@use_bootstrap = yes?('Use bootstrap? (yes/no)')
@use_slim = yes?('Use slim? (yes/no)')
@use_devise = yes?('Use devise? (yes/no)')
@use_carrierwave = yes?('Use carrierwave? (yes/no)')
@use_ckeditor = yes?('Use ckeditor? (yes/no)')
@use_mongodb = yes?('Use mongodb? (yes/no)')
@use_git = yes?('Use git? (yes/no)')

if @use_turbolinks
  insert_into_file 'Gemfile', %(
# turbolinks support
gem 'jquery-turbolinks'
), before: 'group :development, :test do'
end

if @use_redis
  insert_into_file 'Gemfile', %(
# Redis
gem 'redis-objects'
gem 'redis-namespace'
), before: 'group :development do'

  initializer 'redis.rb', <<-CODE
namespace = [Rails.application.class.parent_name, Rails.env].join(':')
if Settings.redis_url
  redis_uri = URI(Settings.redis_url)
  Redis.current = Redis::Namespace.new(namespace, host: redis_uri.host, port: redis_uri.port)
end
  CODE
end

if @use_bootstrap
  insert_into_file 'Gemfile', %(
# Bootstrap & Bootswatch & font-awesome
gem 'autoprefixer-rails'
gem 'bootstrap-sass'
gem 'bootswatch-rails'
gem 'font-awesome-rails'
), before: 'group :development do'

  insert_into_file 'Gemfile', "\n  gem 'twitter-bootstrap-rails'", after: 'group :development do'

  # Bootstrap/Bootswach/Font-Awesome
  remove_file 'app/assets/stylesheets/application.css'
  create_file 'app/assets/stylesheets/application.css.scss', <<-CODE
// Example using 'Cerulean' bootswatch

// Import bootstrap-sprockets
@import "bootstrap-sprockets";

// Import cerulean variables
@import "bootswatch/cerulean/variables";

// Then bootstrap itself
@import "bootstrap";

// Bootstrap body padding for fixed navbar
// body { padding-top: 60px;  }

// And finally bootswatch style itself
@import "bootswatch/cerulean/bootswatch";

// Whatever application styles you have go last
// @import "base";

@import "font-awesome";
  CODE
end

if @use_slim
  insert_into_file 'Gemfile', %(
# slim
gem 'slim'
gem 'slim-rails'
gem 'html2slim'
), before: 'group :development, :test do'

  insert_into_file 'config/application.rb', %(
      g.template_engine :slim), after: 'config.generators do |g|'  
end

if @use_devise
  insert_into_file 'Gemfile', %(
# Authentication
gem 'devise'
gem 'devise-bootstrap-views'
gem 'devise-i18n'
gem 'devise-i18n-views'
# gem 'cancancan'
# gem 'enum_help'
# gem 'rolify'
), before: 'group :development do'
end

if @use_mongodb
  insert_into_file 'Gemfile', %(
# Mongoid
gem 'mongoid'
gem 'bson_ext'
gem 'origin'
gem 'moped'
), before: 'group :development do'
end

if @use_carrierwave
  insert_into_file 'Gemfile', %(
# Upload image files
gem 'carrierwave'
gem 'mini_magick'
), before: 'group :development do'
end

if @use_ckeditor
  insert_into_file 'Gemfile', %(
# Ckeditor integration gem for rails
gem 'ckeditor'
), before: 'group :development do'
end

Bundler.with_clean_env do
  run 'bundle install --path vendor/bundle --jobs=4 --binstubs'
  unless db_name == 'sqlserver' 
    run 'bundle exec rake db:drop'
    run 'bundle exec rake db:create'
  end
  run 'bundle exec cap install'
end

# set rspec
generate 'rspec:install'
run "echo '--color -f d' > .rspec"
remove_file 'spec/rails_helper.rb'
run 'wget https://raw.githubusercontent.com/park-jh/templates/master/src/spec/rails_helper.rb -P spec/'

if @use_turbolinks
  # application.js(turbolink setting)
  insert_into_file 'app/assets/javascripts/application.js', %(
//= require jquery.turbolinks
), after: '//=require jquery_ujs'
end

if @use_bootstrap
  # application.js(bootstrap setting)
  append_file 'app/assets/javascripts/application.js', '//= require bootstrap-sprockets'
  generate 'simple_form:install --bootstrap'
else
  generate 'simple_form:install'
end

if @use_devise
  generate 'devise:install'
  generate 'devise User'
  if @use_bootstrap
    # bootstrapを使う場合は、bootstrap用のテンプレートを生成する。
    generate 'devise:views:bootstrap_templates'
    remove_file 'app/views/layouts/application.html.erb'
    generate 'bootstrap:layout application'
  else
    # bootstrapを使わない場合は、多国語を支援するテンプレートを生成する。
    generate 'devise:views:i18n_templates'
  end
  # 日本語のロケールを生成する。
  generate 'devise:views:locale ja'
  run 'bundle exec rake db:migrate'

  append_file 'config/initializers/devise.rb', <<-CODE
# append to end of config/initializers/devise.rb
Rails.application.config.to_prepare do
  Devise::SessionsController.layout "devise"
  Devise::RegistrationsController.layout proc { |controller| user_signed_in? ? "application" : "devise" }
  Devise::ConfirmationsController.layout "devise"
  Devise::UnlocksController.layout "devise"
  Devise::PasswordsController.layout "devise"
end
CODE

  insert_into_file 'app/controllers/application_controller.rb', %(
  before_action :authenticate_user!), after: 'protect_from_forgery with: :exception'
end

if @use_mongodb
  generate 'mongoid:config'

  puts 'config/mongoidファイルを修正する必要があります。'

  insert_into_file 'spec/rails_helper.rb', %(
require 'rails/mongoid'
), after: "require 'rspec/rails'"

  insert_into_file 'spec/rails_helper.rb',%(
  # Clean/Reset Mongoid DB prior to running each test.
  config.before(:each) do
    Mongoid::Sessions.default.collections.select {|c| c.name !~ /system/ }.each(&:drop)
  end), after: 'config.use_transactional_fixtures = false'
end

if @use_ckeditor && @use_carrierwave
  generate 'ckeditor:install --orm=active_record --backend=dragonfly'
end

# whenever
run 'wheneverize .'

# Kaminari config
generate 'kaminari:config'

run 'bundle exec erb2slim -d app/views' if @use_slim

if @use_git
  # .gitignore
  run 'gibo OSX Ruby Rails SASS Vim > .gitignore' rescue nil
  gsub_file '.gitignore', /^config\/initializers\/secret_token.rb$/, ''
  gsub_file '.gitignore', /config\/secret.yml/, ''

  # git init
  # ------------------------------------------------------------------------------
  git :init
  git :add => '.'
  git :commit => "-a -m 'Initial commit'"
end
