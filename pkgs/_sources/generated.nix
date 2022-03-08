# This file was generated by nvfetcher, please do not modify it manually.
{ fetchgit, fetchurl, fetchFromGitHub }:
{
  auth-thu = {
    pname = "auth-thu";
    version = "v2.2";
    src = fetchFromGitHub ({
      owner = "z4yx";
      repo = "GoAuthing";
      rev = "v2.2";
      fetchSubmodules = false;
      sha256 = "sha256-xvYmtgwAeZF5J9+dv2TCgQeuqOQI3/AiSR7n6FQivoE=";
    });
    vendorSha256 = "sha256-LSGyy4i4JWopX54wWXZwEtRQfijCgA618FeQErwdy8o=";
  };
  fcitx5-pinyin-zhwiki = {
    pname = "fcitx5-pinyin-zhwiki";
    version = "20220226";
    src = fetchurl {
      url = "https://github.com/felixonmars/fcitx5-pinyin-zhwiki/releases/download/0.2.3/zhwiki-20220226.dict";
      sha256 = "sha256-jt0zxrIyO9sd8HFztK8QNOTrj72X2YzSxo/ddQAteVM=";
    };
  };
  mokutil = {
    pname = "mokutil";
    version = "0.5.0";
    src = fetchFromGitHub ({
      owner = "lcp";
      repo = "mokutil";
      rev = "0.5.0";
      fetchSubmodules = false;
      sha256 = "sha256-dt41TCr6RkmE9H+NN8LWv3ogGsK38JtLjVN/b2mbGJs=";
    });
  };
  rait = {
    pname = "rait";
    version = "e84e803641ec3a2dce5670275ea8d5497608f483";
    src = fetchgit {
      url = "https://gitlab.com/NickCao/RAIT";
      rev = "e84e803641ec3a2dce5670275ea8d5497608f483";
      fetchSubmodules = false;
      deepClone = false;
      leaveDotGit = false;
      sha256 = "sha256-vaRPmHrom4GEOuAdILzFpttc4vwcRVQWhLNalCco2qE=";
    };
    vendorSha256 = "sha256-pMltPbi1tOfxIBjLHtSxqSQUy7sMTDa8YJ9PeQp3b3k=";
  };
  smartdns-china-list = {
    pname = "smartdns-china-list";
    version = "74df74cf84a26510bde774128112bb3c3ce0aea2";
    src = fetchFromGitHub ({
      owner = "felixonmars";
      repo = "dnsmasq-china-list";
      rev = "74df74cf84a26510bde774128112bb3c3ce0aea2";
      fetchSubmodules = false;
      sha256 = "sha256-nwmOBTbMhScViVU7s9UBJKP28Kjtj9sm769oS0HGNBc=";
    });
  };
  wemeet = {
    pname = "wemeet";
    version = "2.8.0.3";
    src = fetchurl {
      url = "https://updatecdn.meeting.qq.com/cos/3cdd365cd90f221fb345ab73c4746e1f/TencentMeeting_0300000000_2.8.0.3_x86_64_default.publish.deb";
      sha256 = "sha256-76Bm4PaIo7APwYBKWXp14up+PXS+Eo7NLcWM6Q2nhZ8=";
    };
  };
}
