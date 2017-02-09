#
# Copyright:: Copyright (c) 2016 GitLab Inc.
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

include_recipe 'gitlab::default'
include_recipe 'gitlab-ee::config'

[
  "sentinel",
  "sidekiq-cluster"
].each do |service|
  if node["gitlab"][service]["enable"]
    include_recipe "gitlab-ee::#{service}"
  else
    include_recipe "gitlab-ee::#{service}_disable"
  end
end

include_recipe 'gitlab-ee::ssh_keys'

if node['gitlab']['postgresql']['ha_primary']
  include_recipe 'gitlab-ee::ha_primary'
end

if node['gitlab']['postgresql']['ha_standby']
  include_recipe 'gitlab-ee::ha_standby'
end
