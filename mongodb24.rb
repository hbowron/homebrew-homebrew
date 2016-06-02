class Mongodb24 < Formula
  homepage "https://www.mongodb.org/"
  url "https://fastdl.mongodb.org/src/mongodb-src-r2.4.12.tar.gz"
  sha256 "b239a065a1197f811a3908bdee8d535564b94f2d79da893935e38831ebbac8b3"

  bottle do
    cellar :any
    sha256 "004b4e3bfdb5ee0c00b5568383b5012059d057cc30248f5604afd34fd3cb8382" => :yosemite
    sha256 "c6310fd5ea6f665c1d6aec573024b729c912865fcad25ce6723a293bcde82db7" => :mavericks
    sha256 "d3d6d653817a8e6127d9efa62d0f7338c67d15217acb323b5ad49ae853a719da" => :mountain_lion
  end

  patch do
    url "https://github.com/mongodb/mongo/commit/be4bc7.diff"
    sha256 "63592bb33dbe1662425a4a323a6ad33a6aa25d8e3c28b2bc48e34df57361eeed"
  end

  depends_on "scons" => :build
  depends_on "openssl" => :optional

  # When 2.6 is released this conditional can be removed.
  if MacOS.version < :mavericks
    option "with-boost", "Compile using installed boost, not the version shipped with mongodb"
    depends_on "boost" => :optional
  end

  def install
    args = ["--prefix=#{prefix}", "-j#{ENV.make_jobs}"]

    cxx = ENV.cxx
    if ENV.compiler == :clang && MacOS.version >= :mavericks
      # When 2.6 is released this cxx hack can be removed
      # ENV.append "CXXFLAGS", "-stdlib=libstdc++" does not work with scons
      # so use this hack of appending the flag to the --cxx parameter of the sconscript.
      # mongodb 2.4 can't build with libc++, but defaults to it on Mavericks
      cxx += " -stdlib=libstdc++"
    end

    args << "--64" if MacOS.prefer_64_bit?
    args << "--cc=#{ENV.cc}"
    args << "--cxx=#{cxx}"

    # --full installs development headers and client library, not just binaries
    args << "--full"
    args << "--use-system-boost" if build.with? "boost"

    if build.with? "openssl"
      args << "--ssl"
      args << "--extrapath=#{Formula["openssl"].opt_prefix}"
    end

    scons "install", *args

    (buildpath+"mongod.conf").write mongodb_conf
    etc.install "mongod.conf"

    (var+"mongodb").mkpath
    (var+"log/mongodb").mkpath
  end

  def mongodb_conf; <<-EOS.undent
    # Store data in #{var}/mongodb instead of the default /data/db
    dbpath = #{var}/mongodb

    # Append logs to #{var}/log/mongodb/mongo.log
    logpath = #{var}/log/mongodb/mongo.log
    logappend = true

    # Only accept local connections
    bind_ip = 127.0.0.1
    EOS
  end

  plist_options :manual => "mongod --config #{HOMEBREW_PREFIX}/etc/mongod.conf"

  def plist; <<-EOS.undent
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>Label</key>
      <string>#{plist_name}</string>
      <key>ProgramArguments</key>
      <array>
        <string>#{opt_bin}/mongod</string>
        <string>--config</string>
        <string>#{etc}/mongod.conf</string>
      </array>
      <key>RunAtLoad</key>
      <true/>
      <key>KeepAlive</key>
      <false/>
      <key>WorkingDirectory</key>
      <string>#{HOMEBREW_PREFIX}</string>
      <key>StandardErrorPath</key>
      <string>#{var}/log/mongodb/output.log</string>
      <key>StandardOutPath</key>
      <string>#{var}/log/mongodb/output.log</string>
      <key>HardResourceLimits</key>
      <dict>
        <key>NumberOfFiles</key>
        <integer>1024</integer>
      </dict>
      <key>SoftResourceLimits</key>
      <dict>
        <key>NumberOfFiles</key>
        <integer>1024</integer>
      </dict>
    </dict>
    </plist>
    EOS
  end

  test do
    system "#{bin}/mongod", "--sysinfo"
  end
end
