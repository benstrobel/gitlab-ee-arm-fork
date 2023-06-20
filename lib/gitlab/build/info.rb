
require_relative 'info/git'
require_relative '../build_iteration'
require_relative "../util.rb"
require_relative './info/ci'
require_relative './info/package'
require_relative 'check'
require_relative 'image'

module Build
  class Info
    class << self
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

      # Fetch the package used in AWS AMIs from an S3 bucket
      def ami_deb_package_download_url(arch: 'amd64')
        folder = 'ubuntu-focal'
        folder = "#{folder}_aarch64" if arch == 'arm64'

        package_filename_url_safe = Build::Info::Package.release_version.gsub("+", "%2B")
        "https://#{Info.release_bucket}.#{Info.release_bucket_s3_endpoint}/#{folder}/#{Build::Info::Package.name}_#{package_filename_url_safe}_#{arch}.deb"
      end
    end
  end
end
