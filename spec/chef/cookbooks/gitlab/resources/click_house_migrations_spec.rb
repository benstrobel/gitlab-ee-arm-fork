require 'chef_helper'

RSpec.describe 'click_house_migrations' do
  let(:runner) { ChefSpec::SoloRunner.new(step_into: %w(click_house_migrations)) }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  describe 'run' do
    let(:chef_run) { runner.converge('test_gitlab::click_house_migrations_run') }
    let(:migration_block) { chef_run.rails_migration('clickhouse') }

    it 'runs the migrations with expected attributes' do
      expect(chef_run).to run_rails_migration('clickhouse') do |resource|
        expect(resource.rake_task).to eq('gitlab:clickhouse:migrate')
        expect(resource.logfile_prefix).to eq('gitlab-rails-clickhouse-migrate')
        expect(resource.helper).to be_a(ClickHouseMigrationHelper)
      end
    end

    it 'should notify rails cache clear resource' do
      expect(migration_block).to notify('execute[clear the gitlab-rails cache]')
    end
  end
end