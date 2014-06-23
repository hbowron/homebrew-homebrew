require 'formula'

class SportnginBrewGem < Formula
  homepage 'https://github.com/sportngin/brew-gem'
  url 'https://github.com/sportngin/brew-gem/archive/v0.2.2.tar.gz'
  sha1 '20829c49377e4987ea2212d24e54127d8525ed75'

  def install
    bin.install 'bin/brew-gem'
  end
end
