FROM ubuntu:18.04
RUN apt-get update
RUN apt-get -y install software-properties-common
RUN apt-add-repository ppa:brightbox/ruby-ng
RUN apt-get update
RUN apt-get install -y ruby2.6
RUN apt-get install -y ruby2.6-dev
#bcyrpt make file
RUN apt-get install make
RUN mkdir -p /myapp
WORKDIR /myapp
ADD Gemfile /myapp/Gemfile
RUN apt-get install -y libxslt-dev libxml2-dev zlib1g-dev
RUN apt-get install -y libsqlite3-dev
RUN apt-get install -y libpq-dev
RUN gem install bundler
RUN bundle install
ENV PG_HOST=postgres
ENV PG_USERNAME=postgres
ENV PG_PASSWORD=123456
ADD . /myapp
EXPOSE 9294
ENTRYPOINT ["tail", "-f", "/dev/null"]