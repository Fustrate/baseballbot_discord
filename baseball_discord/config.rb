# frozen_string_literal: true

module BaseballDiscord
  # Servers can be added
  class Config
    def short_name_to_server_id(short_name)
      servers.find { |_, server| server['short_name'] == short_name }&.first
    end

    def verified_role_id(server_id)
      servers.dig(server_id, 'verified_role')
    end

    def verification_enabled?(server_id)
      servers.dig(server_id, 'verification')
    end

    def server(server_id)
      servers[server_id]
    end

    def non_team_channels(server_id)
      servers.dig(server_id, 'non_team_channels') || []
    end

    def non_team_roles(server_id)
      servers.dig(server_id, 'non_team_roles') || []
    end

    def dig(*keys)
      servers.dig(*keys)
    end

    def server_prefixes
      servers
        .select { |_, server| server['prefixes'] }
        .map { |server_id, conf| [server_id, Array(conf['prefixes'])] }
        .to_h
    end

    protected

    def servers
      @servers ||= YAML.safe_load(
        File.open(File.expand_path(__dir__ + '/../config/servers.yml')).read
      ).dig('servers')
    end
  end
end
