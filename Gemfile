source 'https://rubygems.org'

require_relative "lib/gitlab/version"

omnibus_gem_version = Gitlab::Version.new('omnibus', "gitlab-omnibus-ad5d3f98")

gem 'omnibus', git: omnibus_gem_version.remote, branch: omnibus_gem_version.print(false)
gem 'ohai'
gem 'package_cloud'
gem 'thor', '0.18.1' # This specific version is required by package_cloud
gem 'json'
gem 'rspec'
gem 'rake'
gem 'knapsack'
gem 'rubocop'
gem 'docker-api'
gem 'aws-sdk'
gem 'rubocop-rspec'

group :test do
  gem 'byebug'
  gem 'chefspec', '~> 6.0.0'
  gem 'omnibus-ctl', '0.5.0'
  gem 'fantaskspec'
end
