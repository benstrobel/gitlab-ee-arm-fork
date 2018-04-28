#
## Copyright:: Copyright (c) 2018 GitLab.com
## License:: Apache License, Version 2.0
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
## http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
##
#

name 'pgbouncer-exporter'

default_version '0.2.1'

license 'MIT'
license_file 'https://github.com/spreaker/prometheus-pgbouncer-exporter/blob/master/LICENSE.txt'

dependency 'python3'

build do
  env = with_standard_compiler_flags(with_embedded_path)
  command "#{install_dir}/embedded/bin/pip3 install prometheus-pgbouncer-exporter==#{version}", env: env
  command "find #{install_dir}/embedded/lib/python3.4 -name '*.dist-info' -type d -print -exec rm -r {} +"
  command "find #{install_dir}/embedded/lib/python3.4 -name '*.egg-info' -type d -print -exec rm -r {} +"
  command "find #{install_dir}/embedded/lib/python3.4 -name '__pycache__' -type d -print -exec rm -r {} +"
end
