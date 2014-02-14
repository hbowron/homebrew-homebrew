require 'formula'

class SportnginBrewGem < Formula
  homepage 'https://github.com/sportngin/brew-gem'
  head 'https://github.com/sportngin/brew-gem/archive/master.tar.gz'

  def install
    bin.install 'bin/brew-gem'
  end
end
