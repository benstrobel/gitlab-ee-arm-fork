module GitlabCtl
  class UpgradeCheck
    class <<self
      def valid?(ov)
        # If old_version is nil, this is a fresh install
        return true if ov.nil?

        old_version_major = ov.split('.')[0]
        old_version_minor = ov.split('.')[1]
        min_version = min_version()
        min_version_major = min_version.split('.')[0]
        min_version_minor = min_version.split('.')[1]

        old_atleast_min = old_version_major == min_version_major && old_version_minor >= min_version_minor
        old_atleast_min ||= old_version_major > min_version_major

        old_atleast_min
      end

      def min_version
        ENV['MIN_VERSION'] || '16.3'.freeze
      end
    end
  end
end
