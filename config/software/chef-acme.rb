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

name 'chef-acme'
default_version 'v3.1.0'

license 'Apache-2.0'
license_file 'LICENSE'

source git: 'https://github.com/schubergphilis/chef-acme.git'

dependency 'acme-client'
dependency 'compat_resource'

target_path = "#{install_dir}/embedded/cookbooks/acme"

build do
  sync "#{project_dir}/", target_path
end
