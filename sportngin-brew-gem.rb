require 'formula'

class SportnginBrewGem < Formula
  homepage 'https://github.com/sportngin/brew-gem'
  url 'https://github.com/sportngin/brew-gem/archive/v0.5.0.tar.gz'
  sha1 'd3d714164007301bc15b3eb6f1e24982f6e1ac9b'

  def install
    bin.install 'bin/brew-gem'
  end
end
