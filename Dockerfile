ARG RUBY_VERSION=4.0
FROM ruby:${RUBY_VERSION}-alpine

ARG SASHIMI_TANPOPO_VERSION=0.5.3

WORKDIR /work

RUN gem install sashimi_tanpopo --no-doc --version ${SASHIMI_TANPOPO_VERSION}

ENTRYPOINT ["sashimi_tanpopo"]
