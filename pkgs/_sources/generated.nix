# This file was generated by nvfetcher, please do not modify it manually.
{ fetchgit, fetchurl, fetchFromGitHub, dockerTools }:
{
  bird-babel-rtt = {
    pname = "bird-babel-rtt";
    version = "dac2ce348f5ee321c80d219719118292f027c2d2";
    src = fetchFromGitHub {
      owner = "NickCao";
      repo = "bird";
      rev = "dac2ce348f5ee321c80d219719118292f027c2d2";
      fetchSubmodules = false;
      sha256 = "sha256-F1UWNwXuISEhhz7BFolUJa7aSKkNpajYH46YqtcknKg=";
    };
    date = "2024-03-24";
  };
  fcitx5-pinyin-zhwiki = {
    pname = "fcitx5-pinyin-zhwiki";
    version = "20240426";
    src = fetchurl {
      url = "https://github.com/felixonmars/fcitx5-pinyin-zhwiki/releases/download/0.2.4/zhwiki-20240426.dict";
      sha256 = "sha256-SiiF4kvQpgjAFd3122WYy0ReJkVLUc93JVeFHIqc+jg=";
    };
  };
}
