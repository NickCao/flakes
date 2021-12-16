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
  kine = {
    pname = "kine";
    version = "v0.6.5";
    src = fetchFromGitHub ({
      owner = "k3s-io";
      repo = "kine";
      rev = "v0.6.5";
      fetchSubmodules = false;
      sha256 = "sha256-8hK+IzrCmmUC6quTb15dNuIlH4jruKJlQajttcoPqRQ=";
    });
    vendorSha256 = "sha256-CwbjSCtI68Tvk3bwM+t46wr0i+xDNgNkzVvL3ZoLDUA=";
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
    version = "0b4a79d847a20e0ba7411ac74ea7485f42d9eaed";
    src = fetchFromGitHub ({
      owner = "felixonmars";
      repo = "dnsmasq-china-list";
      rev = "0b4a79d847a20e0ba7411ac74ea7485f42d9eaed";
      fetchSubmodules = false;
      sha256 = "sha256-8lDHODztSfOS8ZJ5K2xVr+ucRGm0z6KReyZeFHa0RFY=";
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
