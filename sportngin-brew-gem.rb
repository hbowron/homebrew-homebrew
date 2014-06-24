require 'formula'

class SportnginBrewGem < Formula
  homepage 'https://github.com/sportngin/brew-gem'
  url 'https://github.com/sportngin/brew-gem/archive/v0.3.0.tar.gz'
  sha1 '854a6a66a98eca4423afd27c4c2e92b197d894e2'

  def install
    bin.install 'bin/brew-gem'
  end
end
