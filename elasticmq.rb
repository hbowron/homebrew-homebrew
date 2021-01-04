class Elasticmq < Formula
  desc 'AWS SQS compatible message queue'
  homepage 'https://github.com/softwaremill/elasticmq'
  url 'https://s3-eu-west-1.amazonaws.com/softwaremill-public/elasticmq-server-0.14.6.jar', using: :nounzip
  sha256 '1f42a90360ed430f4d46a2481eb4c9b9f849e1655426104c7ea73fc366bde2b2'

  bottle :unneeded

  depends_on "openjdk@8"

  def install
    jar_name = active_spec.downloader.basename
    mkdir_p [libexec/"bin", libexec/"lib"]
    cp cached_download, libexec/"lib/#{jar_name}"
    jar = libexec/"lib/#{jar_name}"
    File.open(libexec/"bin/elasticmq", 'w') do |f|
      f << <<~EOS
      #!/bin/bash

      java $JAVA_OPTS -jar #{jar}
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
