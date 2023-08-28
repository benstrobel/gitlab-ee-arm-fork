require_relative '../../util'
require_relative '../check'
require_relative 'ci'

module Build
  class Info
    class Git
      class << self
        def branch_name
          # If on CI, branch name from `CI_COMMIT_BRANCH` wins
          result = Build::Info::CI.branch_name

          return result if result

          # If not on CI, attempt to detect branch name
          head_reference = Gitlab::Util.shellout_stdout('git rev-parse --abbrev-ref HEAD')

          # On tags, the shell command will return `HEAD`. If that is not the
          # case, we are on a branch and can return the output we received.
          return head_reference unless head_reference == "HEAD"
        end

        def tag_name
          Build::Info::CI.tag_name || Gitlab::Util.shellout_stdout('git describe --tags --exact-match')
        rescue Gitlab::Util::ShellOutExecutionError => e
          return nil if /fatal: no tag exactly matches/.match?(e.stderr)

          raise "#{e.message}\nSTDOUT: #{e.stdout}\nSTDERR: #{e.stderr}"
        end

        def commit_sha
          commit_sha_raw = Gitlab::Util.get_env('CI_COMMIT_SHA') || Gitlab::Util.shellout_stdout('git rev-parse HEAD')

          commit_sha_raw[0, 8]
        end

        # TODO, merge latest_tag with latest_stable_tag
        # TODO, add tests, needs a repo clone
        def latest_tag
          '16.4.0+ee.0'
        end

        def latest_stable_tag(level: 1)
          '16.4.0+ee.0'
        end

        private

        def sorted_tags_for_edition
          Gitlab::Util.shellout_stdout("git -c versionsort.prereleaseSuffix=rc tag -l '#{tag_match_pattern}' --sort=-v:refname")&.split("\n")
        end

        def tag_match_pattern
          return '*[+.]ee.*' if Build::Check.is_ee?

          '*[+.]ce.*'
        end
      end
    end
  end
end
