require 'formula'

class SportnginBrewGem < Formula
  homepage 'https://github.com/sportngin/brew-gem'
  url 'https://github.com/sportngin/brew-gem/archive/v0.5.2.tar.gz'
  sha1 '00eb2fa55d29fadc44e41905a90eab4c4cf6d1f4'

  def install
    bin.install 'bin/brew-gem'
  end
end
