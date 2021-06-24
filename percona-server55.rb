# typed: false
# frozen_string_literal: true

# Fork of https://github.com/Homebrew/homebrew-versions/blob/f25a3ea77e82b1ae52d651c1e94aaa3b5a0b3b72/percona-server55.rb
class PerconaServer55 < Formula
  desc "Drop-in MySQL replacement"
  homepage "http://www.percona.com"
  url "http://www.percona.com/downloads/Percona-Server-5.5/Percona-Server-5.5.41-37.0/source/tarball/percona-server-5.5.41-37.0.tar.gz"
  version "5.5.41-37.0"
  sha256 "4de65ccbdd6c266f18339c2ea5427a15d90a8ce1ce1c7574aa2e72f685a10833"

  bottle do
    root_url "https://s3.amazonaws.com/sportngin-homebrew-bottles"
    rebuild 1
    sha256 el_capitan: "86938a33e57aff0aa08d65ecfd86a8e726c0d89bedddb37d307485b47c9ea93c"
    sha256 sierra:     "5aff4291cd37abe768efcbc4857bf3d0117aafd0e878251e4aef12a3d63eab89"
  end

  keg_only "keg only with versioned data directory to allow multiple versions on one system.  See: https://www.percona.com/blog/2014/08/26/mysqld_multi-how-to-run-multiple-instances-of-mysql/"

  option :universal
  option "with-tests", "Build with unit tests"
  option "with-embedded", "Build the embedded server"
  option "with-libedit", "Compile with editline wrapper instead of readline"
  option "with-local-infile", "Build with local infile loading support"

  deprecated_option "enable-local-infile" => "with-local-infile"

  depends_on "cmake" => :build
  depends_on "openssl"
  depends_on "pidof"
  depends_on "readline"

  def destination
    @destination ||= "mysql55"
  end

  def install
    # Make sure that data directory exists
    (var/destination).mkpath

    args = [
      ".",
      "-DCMAKE_INSTALL_PREFIX=#{prefix}",
      "-DMYSQL_DATADIR=#{var}/#{destination}",
      "-DINSTALL_MANDIR=#{man}",
      "-DINSTALL_DOCDIR=#{doc}",
      "-DINSTALL_INFODIR=#{info}",
      # CMake prepends prefix, so use share.basename
      "-DINSTALL_MYSQLSHAREDIR=#{share.basename}/mysql",
      "-DWITH_SSL=yes",
      "-DDEFAULT_CHARSET=utf8",
      "-DDEFAULT_COLLATION=utf8_general_ci",
      "-DSYSCONFDIR=#{etc}",
      "-DCMAKE_BUILD_TYPE=RelWithDebInfo",
      # PAM plugin is Linux-only at the moment
      "-DWITHOUT_AUTH_PAM=1",
      "-DWITHOUT_AUTH_PAM_COMPAT=1",
      "-DWITHOUT_DIALOG=1",
    ]

    # To enable unit testing at build, we need to download the unit testing suite
    args << if build.with? "tests"
      "-DENABLE_DOWNLOADS=ON"
    else
      "-DWITH_UNIT_TESTS=OFF"
    end

    # Build the embedded server
    args << "-DWITH_EMBEDDED_SERVER=ON" if build.with? "embedded"

    # Compile with readline unless libedit is explicitly chosen
    args << "-DWITH_READLINE=yes" if build.without? "libedit"

    # Make universal for binding to universal applications
    if build.universal?
      ENV.universal_binary
      args << "-DCMAKE_OSX_ARCHITECTURES=#{Hardware::CPU.universal_archs.as_cmake_arch_flags}"
    end

    # Build with local infile loading support
    args << "-DENABLED_LOCAL_INFILE=1" if build.include? "enable-local-infile"

    system "cmake", *args
    system "make"
    system "make", "install"

    # Don't create databases inside of the prefix!
    # See: https://github.com/mxcl/homebrew/issues/4975
    rm_rf "#{prefix}data"

    # Link the setup script into bin
    ln_s "#{prefix}scripts/mysql_install_db", "#{bin}mysql_install_db"

    # Fix up the control script and link into bin
    inreplace "#{prefix}/support-files/mysql.server" do |s|
      s.gsub!(/^(PATH=".*)(")/, "\\1:#{HOMEBREW_PREFIX}/bin\\2")
    end

    ln_s "#{prefix}/support-files/mysql.server", bin

    # Move mysqlaccess to libexec
    libexec.mkpath
    mv "#{bin}/mysqlaccess", libexec
    mv "#{bin}/mysqlaccess.conf", libexec
  end

  def caveats
    <<~EOS
      Set up databases to run AS YOUR USER ACCOUNT with:
          unset TMPDIR
          mysql_install_db --verbose --user=`whoami` --basedir="$(brew --prefix percona-server55)" --datadir=#{var}/#{destination} --tmpdir=/tmp

      To set up base tables in another folder, or use a different user to run
      mysqld, view the help for mysqld_install_db:
          mysql_install_db --help

      and view the MySQL documentation:
        * http://dev.mysql.com/doc/refman/5.5/en/mysql-install-db.html
        * http://dev.mysql.com/doc/refman/5.5/en/default-privileges.html

      To run as, for instance, user "mysql", you may need to `sudo`:
          sudo mysql_install_db ...options...

      A "/etc/my.cnf" from another install may interfere with a Homebrew-built
      server starting up correctly.

      To connect:
          mysql -uroot
    EOS
  end

  def plist
    <<~EOS
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
          <string>--port=3306</string>
          <string>--basedir=#{opt_prefix}</string>
          <string>--datadir=#{var}/#{destination}</string>
          <string>--pid-file=#{var}/#{destination}/mysqld55.pid</string>
          <string>--socket=#{var}/#{destination}/mysqld55.sock</string>
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
