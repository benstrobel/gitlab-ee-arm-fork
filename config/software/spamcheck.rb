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

name 'spamcheck'
version = Gitlab::Version.new('spamcheck', '2.1.3')

default_version version.print

license 'MIT'
license_file 'LICENSE'

dependency 'python3'

source git: version.remote

relative_path 'src/gitlab-org/spamcheck'

arch = if OhaiHelper.raspberry_pi?
         'armv7l'
       elsif OhaiHelper.arm64?
         'aarch64'
       else
         'x86_64'
       end

numpy_libs = "#{install_dir}/embedded/lib/python3.9/site-packages/numpy.libs"
scipy_libs = "#{install_dir}/embedded/lib/python3.9/site-packages/scipy.libs"

build do
  env = with_standard_compiler_flags(with_embedded_path)

  # We need to download patchelf temporarily to update the rpath of the pre-compiled libraries bundled in the numpy wheel
  release_archive = "patchelf-0.17.2-#{arch}.tar.gz"
  release_url = "https://github.com/NixOS/patchelf/releases/download/0.17.2/#{release_archive}"
  command("curl -fL --retry 3 -o #{release_archive} #{release_url}")
  command("tar -xvf #{release_archive}")

  command "#{install_dir}/embedded/bin/pip3 install pipenv", env: env
  command "#{install_dir}/embedded/bin/pipenv requirements > requirements.txt", env: env
  command "#{install_dir}/embedded/bin/pip3 install -r requirements.txt", env: env

  # Modify rpath for embedded libraries
  command "./bin/patchelf --set-rpath #{install_dir}/embedded/lib:#{numpy_libs} #{numpy_libs}/libgfortran*", env: {}
  command "./bin/patchelf --set-rpath #{install_dir}/embedded/lib:#{numpy_libs} #{numpy_libs}/libopenblas64*", env: {}
  command "./bin/patchelf --set-rpath #{install_dir}/embedded/lib:#{numpy_libs} #{numpy_libs}/libquadmath*", env: {}
  command "./bin/patchelf --set-rpath #{install_dir}/embedded/lib:#{scipy_libs} #{scipy_libs}/libgfortran*", env: {}
  command "./bin/patchelf --set-rpath #{install_dir}/embedded/lib:#{scipy_libs} #{scipy_libs}/libopenblasp*", env: {}

  # Generate gRPC code
  command "#{install_dir}/embedded/bin/python3 -m grpc_tools.protoc --proto_path=${PWD} --python_out=${PWD} --grpc_python_out=${PWD} ${PWD}/api/v1/*.proto", env: env

  # Create service dir and sync source files
  command "mkdir -p #{install_dir}/embedded/service/spamcheck", env: env

  sync './api', "#{install_dir}/embedded/service/spamcheck/api"
  sync './app', "#{install_dir}/embedded/service/spamcheck/app"
  sync './server', "#{install_dir}/embedded/service/spamcheck/server"

  copy './main.py', "#{install_dir}/embedded/service/spamcheck/"
  copy './VERSION', "#{install_dir}/embedded/service/spamcheck/"
end
