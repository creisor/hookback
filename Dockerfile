FROM ruby:2.3.0

ENV APP_HOME /app
RUN mkdir $APP_HOME
RUN mkdir /var/bundle
WORKDIR $APP_HOME
COPY Gemfile* $APP_HOME/
RUN bundle install --deployment --path /var/bundle

COPY . $APP_HOME

CMD ["ruby", "webserver.rb"]
