require_relative 'util'

module Build
  class << self
    def exec(project)
      system(*cmd(project))
    end

    def cmd(project)
      %W[bundle exec omnibus build #{project} --log-level #{log_level}]
    end

    private

    def log_level
      if Gitlab::Util.get_env('BUILD_LOG_LEVEL') && !Gitlab::Util.get_env('BUILD_LOG_LEVEL').empty?
        Gitlab::Util.get_env('BUILD_LOG_LEVEL')
      else
        'info'
      end
    end
  end
end
