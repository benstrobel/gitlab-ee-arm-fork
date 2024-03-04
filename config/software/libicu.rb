#
## Copyright:: Copyright (c) 2014 GitLab B.V.
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

name 'libicu'

version = Gitlab::Version.new('libicu', 'release-74-2')

default_version version.print(false)
display_version version.print(false).delete_prefix('release-').tr('-', '.')

source git: version.remote

license 'MIT'
license_file 'icu4c/LICENSE'

skip_transitive_dependency_licensing true

build do
  env = with_standard_compiler_flags(with_embedded_path)
  env['LD_RPATH'] = "#{install_dir}/embedded/lib"
  cwd = "#{Omnibus::Config.source_dir}/libicu/icu4c/source"

  # defaults for Linux/gcc platform from runConfigureICU
  env['CC'] = 'gcc'
  env['CXX'] = 'g++'
  env['RELEASE_CFLAGS'] = '-O3'
  env['RELEASE_CXXFLAGS'] = '-O3'
  env['DEBUG_CFLAGS'] = '-g'
  env['DEBUG_CXXFLAGS'] = '-g'

  block 'use a custom compiler for OSs with older gcc' do
    if ohai['platform'] == 'centos' && ohai['platform_version'].start_with?('7.')
      env['CC'] = "/opt/rh/devtoolset-8/root/usr/bin/gcc"
      env['CXX'] = "/opt/rh/devtoolset-8/root/usr/bin/g++"
    elsif ohai['platform'] == 'suse' && ohai['platform_version'].start_with?('12.')
      env['CC'] = "/usr/bin/gcc-5"
      env['CXX'] = "/usr/bin/g++-5"
    elsif ohai['platform'] == 'opensuseleap' && ohai['platform_version'].start_with?('15.')
      env['CC'] = "/usr/bin/gcc-8"
      env['CXX'] = "/usr/bin/g++-8"
    elsif ohai['platform'] == 'amazon' && ohai['platform_version'] == '2'
      env['CC'] = "/usr/bin/gcc10-gcc"
      env['CXX'] = "/usr/bin/gcc10-g++"
    end
  end

  command ['./configure',
           "--prefix=#{install_dir}/embedded",
           '--with-data-packaging=archive',
           '--enable-shared',
           '--disable-layoutex',
           '--disable-samples'].join(' '), env: env, cwd: cwd

  make "-j #{workers}", env: env, cwd: cwd
  make 'install', env: env, cwd: cwd

  # The git repository uses the format release-MAJ-MIN for the release tags
  # We need to reference the actual version number to create this link, which
  # is required by Gitaly
  actual_version = default_version.split('-')[1..2].join('.')
  link "#{install_dir}/embedded/share/icu/#{actual_version}", "#{install_dir}/embedded/share/icu/current", force: true
end

project.exclude 'embedded/bin/icu-config'
