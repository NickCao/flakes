# This file was generated by nvfetcher, please do not modify it manually.
{ fetchgit, fetchurl, fetchFromGitHub }:
{
  alps = {
    pname = "alps";
    version = "d4c35f3c3157bece8e50fd95f2ee1081be30d7ae";
    src = fetchgit {
      url = "https://git.sr.ht/~migadu/alps";
      rev = "d4c35f3c3157bece8e50fd95f2ee1081be30d7ae";
      fetchSubmodules = false;
      deepClone = false;
      leaveDotGit = false;
      sha256 = "sha256-xKfRLdfeD7lWdmC0iiq4dOIv2SmzbKH7HcAISCJgdug=";
    };
    vendorSha256 = "sha256-/EQ9IMnjADli+OUHQIv3YUdj2XqOeKiWwEiI8Gbf9Ok=";
  };
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
  material-decoration = {
    pname = "material-decoration";
    version = "e652d62451dc67a9c6bc16c00ccbc38fed3373dd";
    src = fetchFromGitHub ({
      owner = "Zren";
      repo = "material-decoration";
      rev = "e652d62451dc67a9c6bc16c00ccbc38fed3373dd";
      fetchSubmodules = false;
      sha256 = "sha256-Hft2a0Pc2ogn8eXeq0xrbV5PRcfZHgmXrRvANYnFUKA=";
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
    version = "4ae2013118a50f114b62105656b7279d22c0cdcb";
    src = fetchFromGitHub ({
      owner = "felixonmars";
      repo = "dnsmasq-china-list";
      rev = "4ae2013118a50f114b62105656b7279d22c0cdcb";
      fetchSubmodules = false;
      sha256 = "sha256-fOM54DEFWPoXdK/7UmabFhQNGQCMy2XR6/WrDCK4BNw=";
    });
  };
  v2ray-domain-list-community = {
    pname = "v2ray-domain-list-community";
    version = "f988bf27f0998882486e82ed1da980f5c8c3a49d";
    src = fetchFromGitHub ({
      owner = "v2fly";
      repo = "domain-list-community";
      rev = "f988bf27f0998882486e82ed1da980f5c8c3a49d";
      fetchSubmodules = false;
      sha256 = "sha256-XLJlSBmSnnaxWt+hX9xKGxMNJLpFuqDGrpR0i05I9C4=";
    });
    vendorSha256 = "sha256-JuLU9v1ukVfAEtz07tGk66st1+sO4SBz83BlK3IPQwU=";
  };
  v2ray-geoip = {
    pname = "v2ray-geoip";
    version = "8afe1590d40e9f318a5741e9922c12610d916135";
    src = fetchFromGitHub ({
      owner = "v2fly";
      repo = "geoip";
      rev = "8afe1590d40e9f318a5741e9922c12610d916135";
      fetchSubmodules = false;
      sha256 = "sha256-Shi2YxLAfzWOIOElx3JG6jT2tsituP5X4pONFezwKgE=";
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
