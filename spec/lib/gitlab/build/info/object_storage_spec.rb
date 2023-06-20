require 'spec_helper'
require 'gitlab/build/info/object_storage'

RSpec.describe Build::Info::ObjectStorage::GCP do
  before do
    stub_default_package_version
    stub_env_var('GITLAB_ALTERNATIVE_REPO', nil)
    stub_env_var('ALTERNATIVE_PRIVATE_TOKEN', nil)
  end

  describe '.release_bucket' do
    it 'returns the release bucket when on a tag' do
      allow(Build::Check).to receive(:on_tag?).and_return(true)
      expect(described_class.release_bucket).to eq('gitlab-com-pkgs-release')
    end

    it 'returns the build bucket when not on a tag' do
      allow(Build::Check).to receive(:on_tag?).and_return(false)
      expect(described_class.release_bucket).to eq('gitlab-com-pkgs-builds')
    end
  end
end
