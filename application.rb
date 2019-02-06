require 'mobb/base'
require './lib/repp/handler/slack/dirty'
require 'yaml'

target_events = [
  'channel_created',
  'channel_rename',
  'channel_archive',
  "channel_unarchive",
  'channel_deleted',
  "bot_added",
  "team_join",
  "subteam_created",
  "emoji_changed",
]

class Store
  attr_reader :cache

  def initialize(client)
    @client = client
    @cache = {}
    channels
  end

  def channels(refresh = nil)
    @cache[:channels] = @client.channels_list.channels if refresh || !@cache[:channels]
    @cache[:channels]
  end
end

class Application < Mobb::Base
  set :service, 'slack_dirty'

  after do
    @attachments ||= {} # avoid mobb bug
    @attachments[:channel] = ENV['NOTIFY_CHANNEL'] || 'general'
  end

  helpers do
    def event
      @env.event
    end

    def messages
      @messages ||= YAML.load(File.read('./messages.yml'))
    end

    def channel_id2name(id, refresh = nil)
      "<##{id}|#{settings.store.channels(refresh).find { |c| c.id == id }.name}>"
    end
  end

  on /channel_(\w+)/ do |type|
    return unless %w[created rename archive unarchive deleted].include?(type)

    options = case type
    when 'created'
      { channel_name: channel_id2name(event.channel.id, true), user_id: event.channel.user }
    when 'rename'
      old_name = settings.store.channels.find { |c| c.id == event.channel.id }.name
      { old_channel_name: old_name,  channel_name: channel_id2name(event.channel.id, true) }
    when 'archive'
      { channel_name: channel_id2name(event.channel) , user_id: event.user }
    when 'unarchive'
      { channel_name: channel_id2name(event.channel) , user_id: event.user }
    when 'deleted'
      { channel_name: channel_id2name(event.channel) }
    end
    sprintf(messages['channel'][type], options)
  end

  on "bot_added" do
    sprintf(messages['bot']['add'], bot_id: event.bot.id, bot_name: event.bot.name)
  end

  on 'emoji_changed' do
    case event.subtype
    when 'remove'
      event.names.map { |name| sprintf(messages['emoji']['remove'], name: name) }.join("\m") 
    when 'add'
      sprintf(messages['emoji']['add'], name: event.name, url: event.value)
    else
    end
  end
end

Application.run! do |service|
  service.handle_types = target_events
  service.application.settings.set :store, Store.new(service.web_client)
end
