# Fork of https://github.com/Homebrew/homebrew/blob/fe554ca165362b4dc697af9700058396da6385e0/Library/Formula/percona-server.rb
class PerconaServer57 < Formula
  desc "Drop-in MySQL replacement"
  homepage "https://www.percona.com"
  url "https://www.percona.com/downloads/Percona-Server-5.7/Percona-Server-5.7.25-28/source/tarball/percona-server-5.7.25-28.tar.gz"
  sha256 "382c610803a9d8e3b54d16a9fd0bd70584116a831f4f3208b58f4cd5efa5cae3"

  keg_only 'Keg only with versioned data directory to allow multiple versions on one system.  See: https://www.percona.com/blog/2014/08/26/mysqld_multi-how-to-run-multiple-instances-of-mysql/'

  bottle do
    root_url "https://s3.amazonaws.com/sportngin-homebrew-bottles"
    sha256 "d3e6e76ed4ad2cea38a4f26e44eb2d3ef86718223c15fd9d987f33f9989f2b62" => :mojave
  end

  option :universal
  option "with-test", "Build with unit tests"
  option "with-embedded", "Build the embedded server"
  option "with-memcached", "Build with InnoDB Memcached plugin"
  option "with-local-infile", "Build with local infile loading support"

  deprecated_option "enable-local-infile" => "with-local-infile"
  deprecated_option "with-tests" => "with-test"

  depends_on "cmake" => :build
  depends_on "pidof" unless MacOS.version >= :mountain_lion
  depends_on "openssl"

  resource "boost" do
    url "https://downloads.sourceforge.net/project/boost/boost/1.59.0/boost_1_59_0.tar.bz2"
    sha256 "727a932322d94287b62abb1bd2d41723eec4356a7728909e38adb65ca25241ca"
  end

  # Where the database files should be located. Existing installs have them
  # under var/percona, but going forward they will be under var/mysql to be
  # shared with the mysql and mariadb formulae.
  def datadir
    @datadir ||= var/"mysql57"
  end

  def install
    args = %W[
      -DCMAKE_INSTALL_PREFIX=#{prefix}
      -DCMAKE_FIND_FRAMEWORK=LAST
      -DCMAKE_VERBOSE_MAKEFILE=ON
      -DMYSQL_DATADIR=#{datadir}
      -DINSTALL_INCLUDEDIR=include/mysql
      -DINSTALL_MANDIR=share/man
      -DINSTALL_DOCDIR=share/doc/#{name}
      -DINSTALL_INFODIR=share/info
      -DINSTALL_MYSQLSHAREDIR=share/mysql
      -DWITH_SSL=bundled
      -DDEFAULT_CHARSET=utf8
      -DDEFAULT_COLLATION=utf8_general_ci
      -DSYSCONFDIR=#{etc}
      -DCOMPILATION_COMMENT=Homebrew
      -DWITH_EDITLINE=system
      -DCMAKE_BUILD_TYPE=RelWithDebInfo
    ]

    # PAM plugin is Linux-only at the moment
    args.concat %W[
      -DWITHOUT_AUTH_PAM=1
      -DWITHOUT_AUTH_PAM_COMPAT=1
      -DWITHOUT_DIALOG=1
    ]

    # TokuDB is broken on MacOsX
    # https://bugs.launchpad.net/percona-server/+bug/1531446
    args.concat %W[-DWITHOUT_TOKUDB=1]

    # MyRocks is broken on macOS
    # https://jira.percona.com/browse/PS-2285
    args.concat %W[-DWITHOUT_ROCKSDB=1]

    # MySQL >5.7.x mandates Boost as a requirement to build & has a strict
    # version check in place to ensure it only builds against expected release.
    # This is problematic when Boost releases don't align with MySQL releases.
    (buildpath/"boost_1_59_0").install resource("boost")
    args << "-DWITH_BOOST=#{buildpath}/boost_1_59_0"

    # To enable unit testing at build, we need to download the unit testing suite
    if build.with? "test"
      args << "-DENABLE_DOWNLOADS=ON"
    else
      args << "-DWITH_UNIT_TESTS=OFF"
    end

    # Build the embedded server
    args << "-DWITH_EMBEDDED_SERVER=ON" if build.with? "embedded"

    # Build with InnoDB Memcached plugin
    args << "-DWITH_INNODB_MEMCACHED=ON" if build.with? "memcached"

    # Make universal for binding to universal applications
    if build.universal?
      ENV.universal_binary
      args << "-DCMAKE_OSX_ARCHITECTURES=#{Hardware::CPU.universal_archs.as_cmake_arch_flags}"
    end

    # Build with local infile loading support
    args << "-DENABLED_LOCAL_INFILE=1" if build.with? "local-infile"

    system "cmake", *args
    system "make"
    system "make", "install"

    # Don't create databases inside of the prefix!
    # See: https://github.com/Homebrew/homebrew/issues/4975
    rm_rf prefix+"data"

    # Fix up the control script and link into bin
    inreplace "#{prefix}/support-files/mysql.server" do |s|
      s.gsub!(/^(PATH=".*)(")/, "\\1:#{HOMEBREW_PREFIX}/bin\\2")
    end

    bin.install_symlink prefix/"support-files/mysql.server"
  end

  def caveats; <<~EOS
  A "/etc/my.cnf" from another install may interfere with a Homebrew-built
  server starting up correctly.

  To connect:
      mysql -uroot

  To initialize the data directory:
      mysqld --initialize --datadir=#{datadir} --user=#{ENV["USER"]}
  EOS
  end

  def plist; <<~EOS
  <?xml version="1.0" encoding="UTF-8"?>
  <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
  <plist version="1.0">
  <dict>
    <key>KeepAlive</key>
    <true/>
    <key>Label</key>
    <string>#{plist_name}</string>
    <key>ProgramArguments</key>
    <array>
      <string>#{opt_bin}/mysqld_safe</string>
      <string>--user=#{ENV["USER"]}</string>
      <string>--port=33306</string>
      <string>--basedir=#{opt_prefix}</string>
      <string>--datadir=#{datadir}</string>
      <string>--pid-file=#{datadir}/mysqld57.pid</string>
      <string>--socket=#{datadir}/mysqld57.sock</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>WorkingDirectory</key>
    <string>#{var}</string>
  </dict>
  </plist>
  EOS
  end
end
