require 'formula'

class SportnginBrewGem < Formula
  homepage 'https://github.com/sportngin/brew-gem'
  url 'https://github.com/sportngin/brew-gem/archive/v0.2.1.tar.gz'
  sha1 'ab9cfea6a236ebbf2f57a59c023210eefaf355c1'

  def install
    bin.install 'bin/brew-gem'
  end
end
