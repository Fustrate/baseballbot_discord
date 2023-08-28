# frozen_string_literal: true

require 'redd'

class RedditClient
  attr_reader :bot

  def initialize(bot)
    @bot = bot

    client.access = access
  end

  def session = (@session ||= Redd::Models::Session.new client)

  def client = (@client ||= Redd::APIClient.new auth_strategy, limit_time: 5)

  # Always make sure our access token is valid before trying to interact with reddit
  def with_account
    tries ||= 0

    refresh_access! if client.access.expired?

    yield
  rescue Redd::Errors::InvalidAccess
    refresh_access!

    # We *should* only get an invalid access error once, but let's be safe.
    retry if (tries += 1) < 1
  end

  protected

  def access
    @access ||= account_access(bot.db[:accounts].first(id: 1))
  end

  def auth_strategy
    Redd::AuthStrategies::Web.new(
      client_id: ENV.fetch('REDDIT_CLIENT_ID'),
      secret: ENV.fetch('REDDIT_SECRET'),
      redirect_uri: ENV.fetch('REDDIT_REDIRECT_URI'),
      user_agent: 'baseball sub discord bot'
    )
  end

  def account_access(row)
    expires_at = Time.parse row[:expires_at]

    Redd::Models::Access.new(
      access_token: row[:access_token],
      refresh_token: row[:refresh_token],
      scope: row[:scope][1..-2].split(','),
      # Remove 60 seconds so we don't run into invalid credentials
      expires_at: expires_at - 60,
      expires_in: expires_at - Time.now
    )
  end

  def refresh_access!
    client.refresh

    return if client.access.to_h[:error]

    update_token_expiration!(Time.now + client.access.expires_in)

    client
  end

  def update_token_expiration!(expires_at)
    bot.db[:accounts].where(refresh_token: client.access.refresh_token)
      .update(access_token: client.access.access_token, expires_at:)
  end
end
