require_relative '../check'

module Build
  class Info
    class Deploy
      class << self
        OS_MAPPING = {
          'AUTO_DEPLOY_ENVIRONMENT' => 'ubuntu-xenial',
          'PATCH_DEPLOY_ENVIRONMENT' => 'ubuntu-bionic',
          'RELEASE_DEPLOY_ENVIRONMENT' => 'ubuntu-focal',
        }.freeze

        def environment_key
          if Build::Check.is_auto_deploy_tag?
            'AUTO_DEPLOY_ENVIRONMENT'
          elsif Build::Check.is_rc_tag?
            'PATCH_DEPLOY_ENVIRONMENT'
          elsif Build::Check.is_latest_stable_tag?
            'RELEASE_DEPLOY_ENVIRONMENT'
          end
        end

        def environment
          key = environment_key

          return nil if key.nil?

          env = Gitlab::Util.get_env(key)

          abort "Unable to determine which environment to deploy too, #{key} is empty" unless env

          puts "Ready to send trigger for environment(s): #{env}"

          env
        end
      end
    end
  end
end
