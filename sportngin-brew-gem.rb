require 'formula'

class BrewGem < Formula
  homepage 'https://github.com/sportngin/brew-gem'
  url 'https://github.com/sportngin/brew-gem/archive/master.tar.gz'

  def install
    bin.install 'bin/brew-gem'
  end
end
