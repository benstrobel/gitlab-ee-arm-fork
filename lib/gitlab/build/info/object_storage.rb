require_relative '../check'

module Build
  class Info
    class ObjectStorage
      class S3
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
        end
      end

      class GCP
        class << self
          def release_bucket
            # All tagged builds are pushed to the release bucket
            # whereas regular branch builds use a separate one
            gcp_pkgs_release_bucket = Gitlab::Util.get_env('GITLAB_COM_PKGS_RELEASE_BUCKET') || 'gitlab-com-pkgs-release'
            gcp_pkgs_builds_bucket = Gitlab::Util.get_env('GITLAB_COM_PKGS_BUILDS_BUCKET') || 'gitlab-com-pkgs-builds'
            Check.on_tag? ? gcp_pkgs_release_bucket : gcp_pkgs_builds_bucket
          end

          def release_bucket_sa_file
            Gitlab::Util.get_env('GITLAB_COM_PKGS_SA_FILE')
          end
        end
      end
    end
  end
end
