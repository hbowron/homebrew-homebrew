class Elasticmq < Formula
  desc 'AWS SQS compatible message queue'
  homepage 'https://github.com/softwaremill/elasticmq'
  url 'https://s3-eu-west-1.amazonaws.com/softwaremill-public/elasticmq-server-1.3.3.jar', using: :nounzip
  sha256 'cb5b90bc5306ea3f6844995194804fb2b70ab06ac0432e1be14f1f88ef7a3f35'

  depends_on "openjdk@8"

  def install
    jar_name = active_spec.downloader.basename
    mkdir_p [libexec/"bin", libexec/"lib", etc/"elasticmq"]
    cp cached_download, libexec/"lib/#{jar_name}"
    jar = libexec/"lib/#{jar_name}"
    File.open(etc/"elasticmq/elasticmq.conf", 'w') {}
    File.open(libexec/"bin/elasticmq", 'w') do |f|
      f << <<~EOS
      #!/bin/bash

      java $JAVA_OPTS -Dconfig.file=#{etc}/elasticmq/elasticmq.conf -jar #{jar}
      EOS
    end
    bin.install libexec/"bin/elasticmq"
  end

  plist_options :manual => "elasticmq"

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
            <string>#{opt_bin}/elasticmq</string>
          </array>
          <key>EnvironmentVariables</key>
          <dict>
            <key>JAVA_OPTS</key>
            <string>-Xss200000</string>
          </dict>
          <key>RunAtLoad</key>
          <true/>
          <key>WorkingDirectory</key>
          <string>#{var}</string>
          <key>StandardErrorPath</key>
          <string>#{var}/log/elasticmq.log</string>
          <key>StandardOutPath</key>
          <string>#{var}/log/elasticmq.log</string>
        </dict>
      </plist>
    EOS
  end

end
