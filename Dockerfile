FROM registry.opensuse.org/yast/head/containers/yast-ruby:latest
RUN zypper --gpg-auto-import-keys --non-interactive in --no-recommends \
  libboost_regex-devel \
  gcc-c++ \
  libtool \
  yast2-core-devel
COPY . /usr/src/app

