FROM ruby:3.0.1

WORKDIR /usr/src/app
COPY puma.rb config.ru Gemfile Gemfile.lock server.rb ./
COPY public public
COPY views views

RUN gem install bundler -v 2.1.4
RUN bundle config set without development
RUN bundle

CMD ["bundle", "exec", "puma", "-C", "puma.rb"]
