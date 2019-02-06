module Repp
  module Handler
    class Slack
      class Dirty < Slack
        class SlackDirtyReceive < SlackReceive
          interface :event
        end

        class SlackDirtyMessageHandler < SlackMessageHandler
          attr_accessor :handle_types, :web_client

          def handle
            handle_types.each do |type|
              client.on type.to_sym do |message|
                res, receive = process_message(message)
                process_trigger(res, receive)
              end
            end
            client.start!
          end

          def process_message(message)
            receive = if message.instance_of?(Event::Trigger)
                        message
                      else
                        SlackDirtyReceive.new(body: message.type, event: message, user: dummy_user)
                      end

            res = app.call(receive)
            if res.first
              channel_to_post = res.last && res.last[:channel] || receive.channel
              attachments = res.last && res.last[:attachments]
              web_client.chat_postMessage(text: res.first, channel: channel_to_post, as_user: true, attachments: attachments)
            end
            [res, receive]
          end

          class DummyUser
            def name; ''; end
          end

          def dummy_user
            DummyUser.new
          end
        end
      end
      class << self
        attr_reader :application, :web_client
        attr_accessor :handle_types

        def run(app, options = {})

          ::Slack.configure do |config|
            config.token = detect_token
          end
          @client = ::Slack::RealTime::Client.new
          @web_client = ::Slack::Web::Client.new
          @application = app.new

          yield self if block_given?

          handler = Dirty::SlackDirtyMessageHandler.new(@client, @web_client, application)
          handler.handle_types = handle_types
          handler.handle
        end
      end
    end

    register 'slack_dirty', 'Repp::Handler::Slack::Dirty'
  end
end
