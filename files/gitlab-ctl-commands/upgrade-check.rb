require "#{base_path}/embedded/service/omnibus-ctl/lib/gitlab_ctl/upgrade_check"

add_command('upgrade-check', 'Check if the upgrade is acceptable', 2) do
  old_version = ARGV[3]
  new_version = ARGV[4]
  unless GitlabCtl::UpgradeCheck.valid?(old_version, new_version)
    old_major = old_version.split('.').first.to_i
    new_major = new_version.split('.').first.to_i
    warn "It seems you are upgrading from major version #{old_major} to major version #{new_major}." if old_major < new_major
    warn "It is required to upgrade to the latest #{GitlabCtl::UpgradeCheck::MIN_VERSION}.x version first before proceeding."
    warn "Please follow the upgrade documentation at https://docs.gitlab.com/ee/update/index.html#upgrading-to-a-new-major-version"
    Kernel.exit 1
  end
end
