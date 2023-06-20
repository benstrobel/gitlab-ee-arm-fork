module Build
  class Info
    class ObjectStorage
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
