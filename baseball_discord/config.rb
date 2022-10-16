# frozen_string_literal: true

module BaseballDiscord
  # Servers can be added
  class Config
    def short_name_to_server_id(short_name) = servers.find { |_, server| server['short_name'] == short_name }&.first

    def verified_role_id(server_id) = servers.dig(server_id, 'verified_role')

    def verification_enabled?(server_id) = servers.dig(server_id, 'verification')

    def server(server_id) = servers[server_id]

    def non_team_channels(server_id) = (servers.dig(server_id, 'non_team_channels') || [])

    def non_team_roles(server_id) = (servers.dig(server_id, 'non_team_roles') || [])

    def dig(*path) = servers.dig(*path)

    protected

    def servers = (@servers ||= YAML.safe_load(File.read(servers_yml_path))['servers'])

    def servers_yml_path = File.expand_path("#{__dir__}/../config/servers.yml")
  end
end
