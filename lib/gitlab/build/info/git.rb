require 'mixlib/shellout'

require_relative '../check'
require_relative 'ci'

module Build
  class Info
    class Git
      class << self
        def branch_name
          Build::Info::CI.branch_name || `git rev-parse --abbrev-ref HEAD`.strip
        end

        def tag_name
          return unless Build::Check.on_tag?

          Build::Info::CI.tag_name || `git describe --tags --exact-match`.strip
        end

        def commit_sha
          commit_sha_raw = Gitlab::Util.get_env('CI_COMMIT_SHA') || `git rev-parse HEAD`.strip

          commit_sha_raw[0, 8]
        end

        # TODO, merge latest_tag with latest_stable_tag
        # TODO, add tests, needs a repo clone
        def latest_tag
          unless (fact_from_file = fetch_fact_from_file(__method__)).nil?
            return fact_from_file
          end

          version = branch_name.delete_suffix('-stable').tr('-', '.') if Build::Check.on_stable_branch?

          `git -c versionsort.prereleaseSuffix=rc tag -l '#{version}#{Build::Info.tag_match_pattern}' --sort=-v:refname | head -1`.chomp
        end

        def latest_stable_tag(level: 1)
          unless (fact_from_file = fetch_fact_from_file(__method__)).nil?
            return fact_from_file
          end

          version = branch_name.delete_suffix('-stable').tr('-', '.') if Build::Check.on_stable_branch?

          # Level decides tag at which position you want. Level one gives you
          # latest stable tag, two gives you the one just before it and so on.
          output = `git -c versionsort.prereleaseSuffix=rc tag -l '#{version}#{Build::Info.tag_match_pattern}' --sort=-v:refname | awk '!/rc/' | head -#{level}`&.split("\n")&.last

          # If no tags exist that start with the specified version, we need to
          # fall back to the available latest stable tag. For that, we run the
          # same command without the version in the filter argument.
          raise TagsNotFoundError if output.nil?

          output
        rescue TagsNotFoundError
          puts "No tags found in #{version}.x series. Falling back to latest available tag."
          `git -c versionsort.prereleaseSuffix=rc tag -l '#{Build::Info.tag_match_pattern}' --sort=-v:refname | awk '!/rc/' | head -#{level}`.split("\n").last
        end

        private

        def tag_match_pattern
          return '*[+.]ee.*' if Build::Check.is_ee?

          '*[+.]ce.*'
        end

        def fetch_fact_from_file(fact)
          return unless File.exist?("build_facts/#{fact}")

          content = File.read("build_facts/#{fact}").strip
          return content unless content.empty?
        end
      end
    end
  end
end
