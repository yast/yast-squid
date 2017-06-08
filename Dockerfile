FROM yastdevel/ruby:sle12-sp2
RUN zypper --gpg-auto-import-keys --non-interactive in --no-recommends \
  boost-devel \
  gcc-c++ \
  libtool \
  yast2-core-devel
COPY . /usr/src/app

