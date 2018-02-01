FROM yastdevel/ruby
RUN zypper --gpg-auto-import-keys --non-interactive in --no-recommends \
  libboost_regex-devel \
  gcc-c++ \
  libtool \
  yast2-core-devel
COPY . /usr/src/app

