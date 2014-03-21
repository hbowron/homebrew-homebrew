require 'formula'

class SportnginBrewGem < Formula
  homepage 'https://github.com/sportngin/brew-gem'
  url 'https://github.com/sportngin/brew-gem/archive/v0.2.1.tar.gz'
  sha1 '94da3eb30de4a94769ab8fdafd9d8db14ce6743b'

  def install
    bin.install 'bin/brew-gem'
  end
end
