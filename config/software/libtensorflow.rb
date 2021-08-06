#
## Copyright:: Copyright (c) 2021 GitLab Inc.
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

name 'libtensorflow'

version = '2.5.0'
default_version version

source url: "https://storage.googleapis.com/tensorflow/libtensorflow/libtensorflow-cpu-linux-x86_64-#{version}.tar.gz",
       sha256: '96f6b45b318a166066b1e59fa097943d0d8b841eab955316744ca0362e200629'

license 'Apache-2.0'
build do
  command "mkdir -p #{install_dir}/embedded/lib"
  move 'lib/*', "#{install_dir}/embedded/lib"
end
