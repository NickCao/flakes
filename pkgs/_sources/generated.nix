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
  material-decoration = {
    pname = "material-decoration";
    version = "cc5cc399a546b66907629b28c339693423c894c8";
    src = fetchFromGitHub ({
      owner = "Zren";
      repo = "material-decoration";
      rev = "cc5cc399a546b66907629b28c339693423c894c8";
      fetchSubmodules = false;
      sha256 = "sha256-aYlnPFhf+ISVe5Ycryu5BSXY8Lb5OoueMqnWQZiv6Lc=";
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
    version = "85b239c4ac717f9d66224be663ce1996c365f8ca";
    src = fetchFromGitHub ({
      owner = "felixonmars";
      repo = "dnsmasq-china-list";
      rev = "85b239c4ac717f9d66224be663ce1996c365f8ca";
      fetchSubmodules = false;
      sha256 = "sha256-O7CyzAeT10lnChs0NQQqE0EL46hGH6fDc7yMpmKgJUQ=";
    });
  };
  v2ray-geoip = {
    pname = "v2ray-geoip";
    version = "035e318f63a5cc2e49265f33cea5473b4a14d25a";
    src = fetchFromGitHub ({
      owner = "v2fly";
      repo = "geoip";
      rev = "035e318f63a5cc2e49265f33cea5473b4a14d25a";
      fetchSubmodules = false;
      sha256 = "sha256-SpYSHb6FsyWEHrVs8qLW7Gof2Xr0hH8etgOURDFC5iA=";
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
