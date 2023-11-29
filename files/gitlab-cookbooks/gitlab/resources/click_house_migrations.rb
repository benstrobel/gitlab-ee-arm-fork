resource_name :click_house_migrations
provides :click_house_migrations

unified_mode true

property :name, name_property: true

default_action :nothing

action :nothing do
end

action :run do
  omnibus_helper = OmnibusHelper.new(node)
  migration_helper = ClickHouseMigrationHelper.new(node)

  dependent_services = []
  dependent_services << "runit_service[puma]" if omnibus_helper.should_notify?("puma")
  dependent_services << "sidekiq_service[sidekiq]" if omnibus_helper.should_notify?("sidekiq")

  rails_migration "clickhouse" do
    rake_task 'gitlab:clickhouse:migrate'
    logfile_prefix 'gitlab-rails-clickhouse-migrate'
    helper migration_helper

    dependent_services dependent_services
    notifies :run, "execute[clear the gitlab-rails cache]", :immediately
  end
end
