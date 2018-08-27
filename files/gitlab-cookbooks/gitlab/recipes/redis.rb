#
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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

redis_service 'redis' do
  socket_group AccountHelper.new(node).gitlab_group
end

sysctl "net.core.somaxconn" do
  value node['gitlab']['redis']['somaxconn'].to_i
  only_if { node['gitlab']['redis']['port'].to_i.positive? && node['gitlab']['redis']['somaxconn'].to_i.positive? }
end

sysctl "net.ipv4.tcp_max_syn_backlog" do
  value node['gitlab']['redis']['tcp_max_syn_backlog'].to_i
  only_if { node['gitlab']['redis']['port'].to_i.positive? && node['gitlab']['redis']['tcp_max_syn_backlog'].to_i.positive? }
end
