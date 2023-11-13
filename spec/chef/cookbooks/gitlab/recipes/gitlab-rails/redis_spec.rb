require 'chef_helper'

RSpec.describe 'gitlab::gitlab-rails' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: 'templatesymlink').converge('gitlab::default') }
  let(:resque_yml_path) { '/var/opt/gitlab/gitlab-rails/etc/resque.yml' }
  let(:cable_yml_path) { '/var/opt/gitlab/gitlab-rails/etc/cable.yml' }
  let(:redis_yml_path) { '/var/opt/gitlab/gitlab-rails/etc/redis.yml' }
  let(:resque_yml) { get_rendered_yaml(chef_run, resque_yml_path) }
  let(:cable_yml) { get_rendered_yaml(chef_run, cable_yml_path) }
  let(:redis_yml) { get_rendered_yaml(chef_run, redis_yml_path) }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  describe 'Redis settings' do
    context 'with default configuration' do
      cached(:chef_run) { ChefSpec::SoloRunner.new(step_into: 'templatesymlink').converge('gitlab::default') }

      it 'creates resque.yml file with default values' do
        expect(resque_yml).to eq(
          production: {
            url: 'unix:/var/opt/gitlab/redis/redis.socket'
          }
        )
      end

      it 'creates cable.yml file with default values' do
        expect(cable_yml).to eq(
          production: {
            adapter: 'redis',
            url: 'unix:/var/opt/gitlab/redis/redis.socket'
          }
        )
      end

      it 'creates empty redis.yml' do
        expect(redis_yml).to be_nil
      end

      it 'does not create separate instance configurations' do
        RedisHelper::REDIS_INSTANCES.each do |instance|
          expect(chef_run).not_to render_file("/var/opt/gitlab/gitlab-rails/etc/redis.#{instance}.yml")
        end
      end

      it 'deletes stale separate instance config files' do
        RedisHelper::REDIS_INSTANCES.each do |instance|
          expect(chef_run).to delete_link("/opt/gitlab/embedded/service/gitlab-rails/config/redis.#{instance}.yml")
          expect(chef_run).to delete_file("/var/opt/gitlab/gitlab-rails/etc/redis.#{instance}.yml")
        end
      end
    end

    context 'with user specified configuration' do
      context 'with single external Redis instance' do
        cached(:chef_run) { ChefSpec::SoloRunner.new(step_into: 'templatesymlink').converge('gitlab::default') }

        before do
          stub_gitlab_rb(
            gitlab_rails: {
              redis_host: 'redis.example.com',
              redis_port: 5000,
              redis_database: 2,
              redis_password: 'redis-pass'
            }
          )
        end

        it 'creates resque.yml file with specified values' do
          expect(resque_yml).to eq(
            production: {
              url: 'redis://:redis-pass@redis.example.com:5000/2'
            }
          )
        end

        it 'creates cable.yml file with specified values' do
          expect(cable_yml).to eq(
            production: {
              adapter: 'redis',
              url: 'redis://:redis-pass@redis.example.com:5000/2'
            }
          )
        end
      end

      context 'with separate settings for ActionCable' do
        before do
          stub_gitlab_rb(
            gitlab_rails: {
              redis_host: 'redis.example.com',
              redis_port: 5000,
              redis_database: 2,
              redis_password: 'redis-pass',
              redis_actioncable_instance: 'redis://actioncable.example.com',
            }
          )
        end

        it 'creates cable.yml file with specified values' do
          expect(cable_yml).to eq(
            production: {
              adapter: 'redis',
              url: 'redis://actioncable.example.com'
            }
          )
        end
      end

      context 'with TLS settings' do
        before do
          stub_gitlab_rb(
            gitlab_rails: {
              redis_host: 'redis.example.com',
              redis_port: 5000,
              redis_database: 2,
              redis_password: 'redis-pass',
              redis_ssl: true
            }
          )
        end

        it 'creates resque.yml file with specified values' do
          expect(resque_yml).to eq(
            production: {
              url: 'rediss://:redis-pass@redis.example.com:5000/2',
              ssl_params: {
                ca_file: '/opt/gitlab/embedded/ssl/certs/cacert.pem',
                ca_path: '/opt/gitlab/embedded/ssl/certs/'
              }
            }
          )
        end
      end

      context 'with Sentinels' do
        cached(:chef_run) { ChefSpec::SoloRunner.new(step_into: 'templatesymlink').converge('gitlab::default') }

        before do
          stub_gitlab_rb(
            redis: {
              enable: false,
              master_name: 'redis-master',
              master_password: 'redis-pass'
            },
            gitlab_rails: {
              redis_sentinels: [
                { 'host': '10.0.0.2', port: 26379 },
                { 'host': '10.0.0.3', port: 26379 },
                { 'host': '10.0.0.4', port: 26379 },
              ],
              redis_sentinels_password: 'sentinel-pass'
            }
          )
        end

        it 'creates resque.yml file with specified values' do
          expect(resque_yml).to eq(
            production: {
              url: 'redis://:redis-pass@redis-master/',
              sentinels: [
                { host: '10.0.0.2', password: 'sentinel-pass', port: 26379 },
                { host: '10.0.0.3', password: 'sentinel-pass', port: 26379 },
                { host: '10.0.0.4', password: 'sentinel-pass', port: 26379 },
              ]
            }
          )
        end

        it 'creates cable.yml file with specified values' do
          expect(cable_yml).to eq(
            production: {
              adapter: 'redis',
              url: 'redis://:redis-pass@redis-master/',
              sentinels: [
                { host: '10.0.0.2', port: 26379 },
                { host: '10.0.0.3', port: 26379 },
                { host: '10.0.0.4', port: 26379 },
              ]
            }
          )
        end
      end

      context 'with separate Redis instances' do
        before do
          stub_gitlab_rb(
            redis: {
              enable: false,
              master_name: 'redis-master',
              master_password: 'redis-pass'
            },
            gitlab_rails: {
              redis_sentinels: [
                { 'host': '10.0.0.2', port: 26379 },
                { 'host': '10.0.0.3', port: 26379 },
                { 'host': '10.0.0.4', port: 26379 },
              ],
              redis_sentinels_password: 'sentinel-pass',
              redis_queues_instance: 'redis://:queues-redis-pass@redis-queues-master:8888/',
              redis_queues_sentinels: [
                { 'host': '10.0.0.5', port: 26379 },
                { 'host': '10.0.0.6', port: 26379 },
                { 'host': '10.0.0.7', port: 26379 },
              ],
              redis_queues_sentinels_password: 'queues-sentinel-pass'
            }
          )
        end

        it 'creates queues.yml file with specified values' do
          queues_yml = get_rendered_yaml(chef_run, '/var/opt/gitlab/gitlab-rails/etc/redis.queues.yml')

          expect(queues_yml).to eq(
            production: {
              url: 'redis://:queues-redis-pass@redis-queues-master:8888/',
              sentinels: [
                { host: '10.0.0.5', password: 'queues-sentinel-pass', port: 26379 },
                { host: '10.0.0.6', password: 'queues-sentinel-pass', port: 26379 },
                { host: '10.0.0.7', password: 'queues-sentinel-pass', port: 26379 },
              ]
            }
          )
        end
      end

      context 'with cluster instances' do
        before do
          stub_gitlab_rb(
            redis: {
              enable: false,
              master_name: 'redis-master',
              master_password: 'redis-pass'
            },
            gitlab_rails: {
              redis_sentinels: [
                { 'host': '10.0.0.2', port: 26379 },
                { 'host': '10.0.0.3', port: 26379 },
                { 'host': '10.0.0.4', port: 26379 },
              ],
              redis_sentinels_password: 'sentinel-pass',
              redis_cache_instance: 'redis://:cache-redis-pass@redis-cache-master:8888/',
              redis_cache_username: 'cache-username',
              redis_cache_password: 'cache-password',
              redis_cache_cluster_nodes: [
                { 'host': '10.0.0.5', port: 26379 },
                { 'host': '10.0.0.6', port: 26379 },
                { 'host': '10.0.0.7', port: 26379 },
              ]
            }
          )
        end

        it 'creates cache.yml file with specified values' do
          cache_yml = get_rendered_yaml(chef_run, '/var/opt/gitlab/gitlab-rails/etc/redis.cache.yml')

          expect(cache_yml).to eq(
            production: {
              username: 'cache-username',
              password: 'cache-password',
              cluster: [
                { host: '10.0.0.5', port: 26379 },
                { host: '10.0.0.6', port: 26379 },
                { host: '10.0.0.7', port: 26379 },
              ]
            }
          )
        end
      end

      context 'with redis.yml override' do
        before do
          stub_gitlab_rb(
            gitlab_rails: {
              redis_yml_override: {
                cache: {
                  instance: 'redis.cache.instance'
                }
              }
            }
          )
        end

        it 'renders redis.yml with specified values' do
          expect(redis_yml).to eq(
            production: {
              cache: {
                instance: 'redis.cache.instance'
              }
            }
          )
        end
      end
    end
  end
end
