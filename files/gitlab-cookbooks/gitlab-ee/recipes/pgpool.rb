#
# Copyright:: Copyright (c) 2017 GitLab Inc.
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


template "#{node['gitlab']['pgpool']['home']}/pgpool.conf" do
  source 'pgpool.conf.erb'
  mode '0644'
  notifies :restart, 'service[pgpool]', :immediately
end

template "#{node['gitlab']['pgpool']['home']}/pcp.conf" do
  source 'pcp.conf.erb'
  mode '0644'
end

runit_service 'pgpool' do
  options(
    log_directory: node['gitlab']['pgpool']['log_directory'] 
  )
end
