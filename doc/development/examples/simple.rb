require "#{Omnibus::Config.project_root}/lib/omnibus_gitlab/build/info"
require "#{Omnibus::Config.project_root}/lib/omnibus_gitlab/build_iteration"
require "#{Omnibus::Config.project_root}/lib/omnibus_gitlab/ohai_helper.rb"
require "#{Omnibus::Config.project_root}/lib/omnibus_gitlab/openssl_helper"
require "#{Omnibus::Config.project_root}/lib/omnibus_gitlab/util"
require "#{Omnibus::Config.project_root}/lib/omnibus_gitlab/version"

name 'simple'
description 'Simple project to test omnibus changes'

maintainer 'GitLab, Inc. <support@gitlab.com>'
homepage 'https://about.gitlab.com/'

license 'MIT'

install_dir '/opt/simple'

dependency ''

build_version '0.1.1'
