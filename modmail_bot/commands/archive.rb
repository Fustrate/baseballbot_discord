# frozen_string_literal: true

module ModmailBot
  module Commands
    module Archive
      def self.register(bot)
        bot.application_command(:archive) { ArchiveCommand.new(_1).archive! }
        bot.application_command(:unarchive) { ArchiveCommand.new(_1).unarchive! }
      end

      class ArchiveCommand < SlashCommand
        def archive!
          reason = options['reason']

          modmail_id = bot.redis.hget('discord_to_modmail', channel.id)

          return error_message('Could not find modmail for this channel.') unless modmail_id

          update_modmail!(modmail_id, true, reason)

          respond_with embed: archived_embed(reason)
        end

        def unarchive!
          reason = options['reason']

          modmail_id = bot.redis.hget('discord_to_modmail', channel.id)

          return error_message('Could not find modmail for this channel.') unless modmail_id

          update_modmail!(modmail_id, false, reason)

          respond_with embed: unarchived_embed(reason)
        end

        protected

        def modmail = (@modmail ||= bot.reddit.session.modmail)

        def archived_embed(reason)
          {
            title: 'Archived',
            description: reason
          }
        end

        def unarchived_embed(reason)
          {
            title: 'Unarchived',
            description: reason
          }
        end

        def update_modmail!(modmail_id, archived, reason)
          bot.reddit.with_account do
            conversation = modmail.get(modmail_id)

            conversation.reply(
              ["#{archived ? 'Archived' : 'Unarchived'} by #{user.nick}", reason].compact.join(': '),
              internal: true
            )

            archived ? conversation.archive : conversation.unarchive
          end
        end
      end
    end
  end
end
