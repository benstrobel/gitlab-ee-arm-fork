module Build
  class Info
    class QA
      class << self
        def image
          OmnibusGitlab::Util.get_env('QA_IMAGE') || "#{OmnibusGitlab::Util.get_env('CI_REGISTRY')}/#{Build::Info::Components::GitLabRails.project_path}/#{Build::Info::Package.name}-qa:#{Build::Info::Components::GitLabRails.ref(prepend_version: false)}"
        end
      end
    end
  end
end
