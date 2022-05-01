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
  bird-babel-rtt = {
    pname = "bird-babel-rtt";
    version = "bb858a8673c5a3cb743327751ce11c7995c0afb9";
    src = fetchFromGitHub ({
      owner = "tohojo";
      repo = "bird";
      rev = "bb858a8673c5a3cb743327751ce11c7995c0afb9";
      fetchSubmodules = false;
      sha256 = "sha256-T6CGH+EEHwNJ/N22/8c1Hu/6vVSbLAQ0xMTAaynJ6Tc=";
    });
  };
  fcitx5-pinyin-zhwiki = {
    pname = "fcitx5-pinyin-zhwiki";
    version = "20220416";
    src = fetchurl {
      url = "https://github.com/felixonmars/fcitx5-pinyin-zhwiki/releases/download/0.2.4/zhwiki-20220416.dict";
      sha256 = "sha256-vyvsychfpRMSQWgxQfCxD3QllmKBjDdcbIvJiEDfz+8=";
    };
  };
  jtag-remote-server = {
    pname = "jtag-remote-server";
    version = "c359ed983187a6b450152c29fefd2e013894d79b";
    src = fetchFromGitHub ({
      owner = "jiegec";
      repo = "jtag-remote-server";
      rev = "c359ed983187a6b450152c29fefd2e013894d79b";
      fetchSubmodules = false;
      sha256 = "sha256-geYXrAcknbfyIZ/3XkYjnHR2MhG13FDxqwO8eywxpSM=";
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
  riscv-openocd = {
    pname = "riscv-openocd";
    version = "9d737af35126c3a857e1c6a3356ab3879e92b6eb";
    src = fetchFromGitHub ({
      owner = "riscv";
      repo = "riscv-openocd";
      rev = "9d737af35126c3a857e1c6a3356ab3879e92b6eb";
      fetchSubmodules = true;
      sha256 = "sha256-B7lFvBete5C3bGiYmuRaWdpEaDe2vk1nFcF827QBJ6s=";
    });
  };
  smartdns-china-list = {
    pname = "smartdns-china-list";
    version = "8c8bf255021b59c240373e6e25df31dead7ae74a";
    src = fetchFromGitHub ({
      owner = "felixonmars";
      repo = "dnsmasq-china-list";
      rev = "8c8bf255021b59c240373e6e25df31dead7ae74a";
      fetchSubmodules = false;
      sha256 = "sha256-TC+ScsZMtVZuUtG4jEdE035YNbvMsadOYsqgKzl2U2U=";
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
