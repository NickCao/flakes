# This file was generated by nvfetcher, please do not modify it manually.
{ fetchgit, fetchurl, fetchFromGitHub, dockerTools }:
{
  bird-babel-rtt = {
    pname = "bird-babel-rtt";
    version = "69372dc9aa8b234b79999c4cdcdfa3aa05e3a672";
    src = fetchFromGitHub {
      owner = "NickCao";
      repo = "bird";
      rev = "69372dc9aa8b234b79999c4cdcdfa3aa05e3a672";
      fetchSubmodules = false;
      sha256 = "sha256-b9RVWZmzT6E7XAb+GW6YXcZXmG+nQBKYjOXEZNPkGpQ=";
    };
    date = "2023-06-02";
  };
  fcitx5-pinyin-zhwiki = {
    pname = "fcitx5-pinyin-zhwiki";
    version = "20230605";
    src = fetchurl {
      url = "https://github.com/felixonmars/fcitx5-pinyin-zhwiki/releases/download/0.2.4/zhwiki-20230605.dict";
      sha256 = "sha256-G44bgOWpnQEbP78idcOobEUm2m+7cYM+UCqyJu+D+9E=";
    };
  };
}
