
require_relative 'info/git'
require_relative '../build_iteration'
require_relative "../util.rb"
require_relative './info/ci'
require_relative './info/package'
require_relative 'check'
require_relative 'image'

module Build
  class Info
    DEPLOYER_OS_MAPPING = {
      'AUTO_DEPLOY_ENVIRONMENT' => 'ubuntu-xenial',
      'PATCH_DEPLOY_ENVIRONMENT' => 'ubuntu-bionic',
      'RELEASE_DEPLOY_ENVIRONMENT' => 'ubuntu-focal',
    }.freeze

    class << self
      def docker_tag
        Gitlab::Util.get_env('IMAGE_TAG') || Build::Info::Package.release_version.tr('+', '-')
      end

      def qa_image
        Gitlab::Util.get_env('QA_IMAGE') || "#{Gitlab::Util.get_env('CI_REGISTRY')}/#{Build::Info::Components::GitLabRails.project_path}/#{Build::Info::Package.name}-qa:#{Build::Info::Components::GitLabRails.ref(prepend_version: false)}"
      end

      def release_bucket
        # Tag builds are releases and they get pushed to a specific S3 bucket
        # whereas regular branch builds use a separate one
        downloads_bucket = Gitlab::Util.get_env('RELEASE_BUCKET') || "downloads-packages"
        builds_bucket = Gitlab::Util.get_env('BUILDS_BUCKET') || "omnibus-builds"
        Check.on_tag? ? downloads_bucket : builds_bucket
      end

      def release_bucket_region
        Gitlab::Util.get_env('RELEASE_BUCKET_REGION') || "eu-west-1"
      end

      def release_bucket_s3_endpoint
        Gitlab::Util.get_env('RELEASE_BUCKET_S3_ENDPOINT') || "s3.amazonaws.com"
      end

      def gcp_release_bucket
        # All tagged builds are pushed to the release bucket
        # whereas regular branch builds use a separate one
        gcp_pkgs_release_bucket = Gitlab::Util.get_env('GITLAB_COM_PKGS_RELEASE_BUCKET') || 'gitlab-com-pkgs-release'
        gcp_pkgs_builds_bucket = Gitlab::Util.get_env('GITLAB_COM_PKGS_BUILDS_BUCKET') || 'gitlab-com-pkgs-builds'
        Check.on_tag? ? gcp_pkgs_release_bucket : gcp_pkgs_builds_bucket
      end

      def gcp_release_bucket_sa_file
        Gitlab::Util.get_env('GITLAB_COM_PKGS_SA_FILE')
      end

      def log_level
        if Gitlab::Util.get_env('BUILD_LOG_LEVEL') && !Gitlab::Util.get_env('BUILD_LOG_LEVEL').empty?
          Gitlab::Util.get_env('BUILD_LOG_LEVEL')
        else
          'info'
        end
      end

      # Fetch the package used in AWS AMIs from an S3 bucket
      def ami_deb_package_download_url(arch: 'amd64')
        folder = 'ubuntu-focal'
        folder = "#{folder}_aarch64" if arch == 'arm64'

        package_filename_url_safe = Build::Info::Package.release_version.gsub("+", "%2B")
        "https://#{Info.release_bucket}.#{Info.release_bucket_s3_endpoint}/#{folder}/#{Build::Info::Package.name}_#{package_filename_url_safe}_#{arch}.deb"
      end

      def release_file_contents
        repo = Gitlab::Util.get_env('PACKAGECLOUD_REPO') # Target repository

        download_url = if /dev.gitlab.org/.match?(Build::Info::CI.api_v4_url)
                         Build::Info::CI.package_download_url
                       else
                         Build::Info::CI.triggered_package_download_url
                       end

        raise "Unable to identify package download URL." unless download_url

        contents = []
        contents << "PACKAGECLOUD_REPO=#{repo.chomp}\n" if repo && !repo.empty?
        contents << "RELEASE_PACKAGE=#{Build::Info::Package.name}\n"
        contents << "RELEASE_VERSION=#{Build::Info::Package.release_version}\n"
        contents << "DOWNLOAD_URL=#{download_url}\n"
        contents << "CI_JOB_TOKEN=#{Build::Info::CI.job_token}\n"
        contents.join
      end

      def deploy_env_key
        if Build::Check.is_auto_deploy_tag?
          'AUTO_DEPLOY_ENVIRONMENT'
        elsif Build::Check.is_rc_tag?
          'PATCH_DEPLOY_ENVIRONMENT'
        elsif Build::Check.is_latest_stable_tag?
          'RELEASE_DEPLOY_ENVIRONMENT'
        end
      end

      def deploy_env
        key = deploy_env_key

        return nil if key.nil?

        env = Gitlab::Util.get_env(key)

        abort "Unable to determine which environment to deploy too, #{key} is empty" unless env

        puts "Ready to send trigger for environment(s): #{env}"

        env
      end
    end
  end
end
