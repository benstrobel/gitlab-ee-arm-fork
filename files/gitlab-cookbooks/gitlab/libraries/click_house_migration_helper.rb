# frozen_string_literal: true

require_relative 'rails_migration_helper.rb'

class ClickHouseMigrationHelper < RailsMigrationHelper
  def initialize(node)
    @node = node
    @status_file_prefix = 'clickhouse-migrate'
    @attributes_node = node['gitlab']['gitlab_rails']
  end

  private

  def connection_digest
    OpenSSL::Digest::SHA256.hexdigest(Marshal.dump(@attributes_node['clickhouse_databases']))
  end
end
