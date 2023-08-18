# frozen_string_literal: true

# Copyright (c) Valencia Management Group
# All rights reserved.

module Discordrb
  class Channel
    def start_forum_thread(name, message, auto_archive_duration: 10080, applied_tags: [])
      payload = { name:, message:, auto_archive_duration:, applied_tags: }

      data = API::Channel.start_forum_thread(@bot.token, @id, **payload)

      Channel.new(JSON.parse(data), @bot, @server)
    end
  end

  module API
    module Channel
      module_function

      # Start a thread without an associated message.
      # https://discord.com/developers/docs/resources/channel#start-thread-in-forum-or-media-channel
      def start_forum_thread(token, channel_id, **payload)
        Discordrb::API.request(
          :channels_cid_threads,
          channel_id,
          :post,
          "#{Discordrb::API.api_base}/channels/#{channel_id}/threads",
          payload.to_json,
          Authorization: token,
          content_type: :json
        )
      end
    end
  end
end
