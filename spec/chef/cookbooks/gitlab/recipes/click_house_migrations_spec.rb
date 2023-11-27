require 'chef_helper'

# NOTE: These specs do not verify whether the code actually ran
# Nor whether the resource inside of the recipe was notified correctly.
# At this moment they only verify whether the expected commands are passed
# to the resource block.

RSpec.describe 'gitlab::clickhouse-migrations' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  it "doesn't run migrations if ClickHouse databases are not configured" do
    expect(chef_run).not_to run_rails_migration('clickhouse')
  end

  context 'when migration should run' do
    before do
      stub_gitlab_rb(
        gitlab_rails: {
          clickhouse_databases: {
            main: {
              database: 'production',
              url: 'https://example.com/path',
              username: 'gitlab',
              password: 'password'
            }
          }
        }
      )
    end

    let(:migration_block) { chef_run.rails_migration('clickhouse') }

    it 'runs the migrations with expected attributes' do
      expect(chef_run).to run_rails_migration('clickhouse') do |resource|
        expect(resource.rake_task).to eq('gitlab:clickhouse:migrate')
        expect(resource.logfile_prefix).to eq('gitlab-rails-clickhouse-migrate')
        expect(resource.helper).to be_a(ClickHouseMigrationHelper)
      end
    end

    it 'should notify rails cache clear resource' do
      expect(migration_block).to notify(
        'execute[clear the gitlab-rails cache]')
    end
  end

  context 'with auto_migrate off' do
    before { stub_gitlab_rb(gitlab_rails: { auto_migrate: false }) }

    it 'skips running the migrations' do
      expect(chef_run).not_to run_rails_migration('clickhouse')
    end
  end
end
