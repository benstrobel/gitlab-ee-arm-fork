#
# Copyright 2012-2014 Chef Software, Inc.
# Copyright 2017-2023 GitLab Inc.
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

name 'shellwords-gem'
# The version here should be in agreement with /Gemfile.lock so that our rspec
# testing stays consistent with the package contents.
default_version '0.1.0'

license 'BSD-2-Clause'
license_file 'LICENSE.txt'

skip_transitive_dependency_licensing true

dependency 'ruby'

build do
  patch source: "license/add-license-file.patch"
  env = with_standard_compiler_flags(with_embedded_path)

  gem 'install shellwords' \
      " --clear-sources" \
      " -s https://rubygems.org" \
      " --version '#{version}'" \
      " --bindir '#{install_dir}/embedded/bin'" \
      ' --no-document', env: env
end
