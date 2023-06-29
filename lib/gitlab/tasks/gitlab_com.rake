require_relative '../deployer_helper'
require_relative '../util'

namespace :gitlab_com do
  desc 'Tasks related to gitlab.com.'
  task :deployer do
    abort "This task requires DEPLOYER_TRIGGER_TOKEN to be set" unless Gitlab::Util.get_env('DEPLOYER_TRIGGER_TOKEN')

    unless Build::Info::Package.name == "gitlab-ee"
      puts "#{Build::Info::Package.name} is not an ee package, not doing anything."
      exit
    end

    deploy_env = Build::Info::Deploy.environment
    operating_systems = Build::Info::Package.file_list.map { |path| path.split("/")[1] }.uniq

    unless operating_systems.include?(Build::Info::Deploy::OS_MAPPING[Build::Info::Deploy.environment_key])
      puts "Deployment to #{deploy_env} not to be triggered from this build (#{operating_systems.join(',')})."
      exit
    end

    if deploy_env.nil?
      puts 'Unable to determine which environment to deploy to, exiting...'
      exit
    end

    trigger_token = Gitlab::Util.get_env('DEPLOYER_TRIGGER_TOKEN')
    trigger_ref = Build::Check.is_auto_deploy? && Build::Check.ci_commit_tag? ? Gitlab::Util.get_env('CI_COMMIT_TAG') : :master

    if Build::Check.is_auto_deploy?
      puts 'Auto-deploys are handled in release-tools, exiting...'
      exit
    end

    # We do not support auto-deployments or triggered deployments
    # directly to production from the omnibus pipeline, this check is here
    # for safety
    raise NotImplementedError, "Environment #{deploy_env} is not supported" if deploy_env == 'gprd'

    deployer_helper = DeployerHelper.new(trigger_token, deploy_env, trigger_ref)
    url = deployer_helper.trigger_deploy
    puts "Deployer build triggered at #{url} on #{trigger_ref} for the #{deploy_env} environment"
  end
end
