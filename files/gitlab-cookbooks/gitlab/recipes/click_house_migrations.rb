#
# Copyright:: Copyright (c) 2014 GitLab.com
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

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

  only_if { migration_helper.attributes_node['auto_migrate'] }
end
