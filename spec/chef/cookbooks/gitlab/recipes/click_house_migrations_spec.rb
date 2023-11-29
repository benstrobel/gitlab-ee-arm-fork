require 'chef_helper'

# NOTE: These specs do not verify whether the code actually ran
# Nor whether the resource inside of the recipe was notified correctly.
# At this moment they only verify whether the expected commands are passed
# to the resource block.

RSpec.describe 'gitlab::clickhouse-migrations' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }
  let(:clickhouse_databases) { {} }
  let(:auto_migrate) { true }

  before do
    allow(Gitlab).to receive(:[]).and_call_original

    stub_gitlab_rb(
      gitlab_rails: {
        clickhouse_databases: clickhouse_databases,
        auto_migrate: auto_migrate
      }
    )
  end

  it "doesn't run migrations if ClickHouse databases are not configured" do
    expect(chef_run).not_to run_click_house_migrations('click_house_migrate')
  end

  context 'when ClickHouse databases are configured' do
    let(:clickhouse_databases) do
      {
        main: {
          database: 'production',
          url: 'https://example.com/path',
          username: 'gitlab',
          password: 'password'
        }
      }
    end

    it 'runs the migrations with expected attributes' do
      expect(chef_run).to run_click_house_migrations('click_house_migrate')
    end

    context 'with auto_migrate off' do
      let(:auto_migrate) { false }

      it 'skips running the migrations' do
        expect(chef_run).not_to run_click_house_migrations('click_house_migrate')
      end
    end
  end
end
