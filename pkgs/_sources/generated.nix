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
    version = "20220416";
    src = fetchurl {
      url = "https://github.com/felixonmars/fcitx5-pinyin-zhwiki/releases/download/0.2.4/zhwiki-20220416.dict";
      sha256 = "sha256-vyvsychfpRMSQWgxQfCxD3QllmKBjDdcbIvJiEDfz+8=";
    };
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
    version = "031320b3b0a15496ae03e5427094c11b92cb3c40";
    src = fetchFromGitHub ({
      owner = "felixonmars";
      repo = "dnsmasq-china-list";
      rev = "031320b3b0a15496ae03e5427094c11b92cb3c40";
      fetchSubmodules = false;
      sha256 = "sha256-WwT61CRypr24aBBc5p/PAJ8aWCADX1IJK9OK3zlM1s4=";
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
