FROM ruby:2.6.1-alpine3.9

WORKDIR /app
ADD . /app
RUN apk update
RUN apk add --no-cache g++ musl-dev make openssl-dev
RUN bundle install
ENTRYPOINT bundle exec ruby application.rb
