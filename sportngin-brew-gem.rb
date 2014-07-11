require 'formula'

class SportnginBrewGem < Formula
  homepage 'https://github.com/sportngin/brew-gem'
  url 'https://github.com/sportngin/brew-gem/archive/v0.4.0.tar.gz'
  sha1 'e99638d9d970df4ce669959b269055e75f348380'

  def install
    bin.install 'bin/brew-gem'
  end
end
