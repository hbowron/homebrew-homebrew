class Mongodb24 < Formula
  homepage "https://www.mongodb.org/"
  url "https://fastdl.mongodb.org/src/mongodb-src-r2.4.12.tar.gz"
  sha256 "b239a065a1197f811a3908bdee8d535564b94f2d79da893935e38831ebbac8b3"

  bottle do
    root_url "https://s3.amazonaws.com/sportngin-homebrew-bottles"
    cellar :any_skip_relocation
    rebuild 1
    sha256 "b83a20e8e440726fc0798d24d17a3781b811e959239d19d5ef0ee22aba7f5b83" => :el_capitan
    sha256 "4e6dbc25e9cb2a82d1047b4cc96314a3afe1afc6fb2f4d5f464201661419d644" => :sierra
    sha256 "4b1d38da7eeb3ecfa7e2b5225fbe86c28f71285b33eb763d2ea4e7f49d9d5e42" => :high_sierra
  end

  patch do
    url "https://github.com/mongodb/mongo/commit/be4bc7.diff"
    sha256 "92a395063451cb1fbdc13c0fe7db5c92704f8a5ac5810f5dad765d14831226ea"
  end

  patch do
    url "https://raw.githubusercontent.com/sportngin/homebrew-homebrew/e191342/patches/mongo-2.4.12-pointer-comparison.patch"
    sha256 "42df26a8fd73db69b68b83300baa2a33722e2b87732714b06d4ef7bee68fa08e"
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
