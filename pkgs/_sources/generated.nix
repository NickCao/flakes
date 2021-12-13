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
    version = "19076c4a9e52c75c5b5a259f3b47bc3ef703eeb4";
    src = fetchgit {
      url = "https://gitlab.com/NickCao/RAIT";
      rev = "19076c4a9e52c75c5b5a259f3b47bc3ef703eeb4";
      fetchSubmodules = false;
      deepClone = false;
      leaveDotGit = false;
      sha256 = "sha256-KVXy01l6GsT+cZu7QNCnrS6FtEAGayXTnsBYTT76Dwg=";
    };
    vendorSha256 = "sha256-55Zu1g+pwTt6dU1QloxfFkG2dbnK5gg84WvRhz2ND3M=";
  };
  rime-pinyin-zhwiki = {
    pname = "rime-pinyin-zhwiki";
    version = "20210923";
    src = fetchurl {
      url = "https://github.com/felixonmars/fcitx5-pinyin-zhwiki/releases/download/0.2.3/zhwiki-20210923.dict.yaml";
      sha256 = "sha256-1bNEKG6LtG6JGAcKUSF+9uYH1vijy8uFHVt+c5zidcM=";
    };
  };
  smartdns-china-list = {
    pname = "smartdns-china-list";
    version = "f4595d51d556a6363d06d9664e1dd2934bb0f389";
    src = fetchFromGitHub ({
      owner = "felixonmars";
      repo = "dnsmasq-china-list";
      rev = "f4595d51d556a6363d06d9664e1dd2934bb0f389";
      fetchSubmodules = false;
      sha256 = "sha256-UfidTBoUM6NhB0WxIuzekx2G4KTRPMHi3bqTu/MxN+o=";
    });
  };
  v2ray-geoip = {
    pname = "v2ray-geoip";
    version = "97f4acb31d926ae31bb3cdc5c8948d8dcdddca79";
    src = fetchFromGitHub ({
      owner = "v2fly";
      repo = "geoip";
      rev = "97f4acb31d926ae31bb3cdc5c8948d8dcdddca79";
      fetchSubmodules = false;
      sha256 = "sha256-kYMp/D7xVpBTu35YXq45bR2XebpVOW57UAc7H/6px/U=";
    });
  };
  wemeet = {
    pname = "wemeet";
    version = "2.8.0.1";
    src = fetchurl {
      url = "https://updatecdn.meeting.qq.com/cos/196cdf1a3336d5dca56142398818545f/TencentMeeting_0300000000_2.8.0.1_x86_64.publish.deb";
      sha256 = "sha256-LWPPLDZ7YVixN+xa+FqJo5dM+RW/AZM9nw2z9digIxc=";
    };
  };
}
