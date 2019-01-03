require 'mixlib/shellout'

module ShellOutHelper
  def do_shell_out(cmd, user = nil, cwd = nil)
    o = Mixlib::ShellOut.new(cmd, user: user, cwd: cwd)
    o.run_command
    o
  rescue Errno::EACCES
    Chef::Log.info("Cannot execute #{cmd}.")
    o
  rescue Errno::ENOENT
    Chef::Log.info("#{cmd} does not exist.")
    o
  end

  def cmd_stdout(cmd)
    o = do_shell_out(cmd)
    o.stdout
  end

  def cmd_stderr(cmd)
    o = do_shell_out(cmd)
    o.stderr
  end

  def success?(cmd)
    o = do_shell_out(cmd)
    o.exitstatus.zero?
  end

  def failure?(cmd)
    o = do_shell_out(cmd)
    o.exitstatus != 0
  end
end
