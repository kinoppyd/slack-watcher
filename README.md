# Slack Watcher Bot

This bot watches your Slack workspace's Real Time Messaging API and notify if some changes in your warkspace. (e.g. Add or remove channel, enoji or bot)

# How to use

Bundler

```shell
git clone https://github.com/kinoppyd/slack-watcher.git ~/.slack_watcher
cd ~/.slack_watcher
vim messages.yml # Edit messages if you want
bundle install
SLACK_TOKEN=xxxx NOTIFY_CHANNEL=channel_name bundle exec ruby application.rb
```

or Docker

```shell
git clone https://github.com/kinoppyd/slack-watcher.git ~/.slack_watcher
cd ~/.slack_watcher
vim messages.yml # Edit messages if you want
docker build . -t slack_watcher
docker run -e SLACK_TOKEN=xxxx -e NOTIFY_CHANNEL=channel_name slack_watcher
```

# LICENSE

MIT
