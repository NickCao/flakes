# This file was generated by nvfetcher, please do not modify it manually.
{ fetchgit, fetchurl }:
{
  auth-thu = {
    pname = "auth-thu";
    version = "v2.2";
    src = fetchgit {
      url = "https://github.com/z4yx/GoAuthing";
      rev = "v2.2";
      fetchSubmodules = false;
      deepClone = false;
      leaveDotGit = false;
      sha256 = "10dy49afirqy94ig1pq8wjlaw1w1q9jbz7fz4xwr2y801jv2dxn6";
    };
    vendorSha256 = "sha256-LSGyy4i4JWopX54wWXZwEtRQfijCgA618FeQErwdy8o=";
  };
  chasquid = {
    pname = "chasquid";
    version = "v1.8";
    src = fetchgit {
      url = "https://github.com/albertito/chasquid";
      rev = "v1.8";
      fetchSubmodules = false;
      deepClone = false;
      leaveDotGit = false;
      sha256 = "1zg9ppjgvzywhkand8sk50d4gnxk9z52a9w24n5mlm5yjawrzsi2";
    };
    vendorSha256 = "sha256-1H1zTRzX6a4mBSHIJvLeVC9GIKE8qUvwbgfRw297vq4=";
  };
  material-decoration = {
    pname = "material-decoration";
    version = "e652d62451dc67a9c6bc16c00ccbc38fed3373dd";
    src = fetchgit {
      url = "https://github.com/Zren/material-decoration";
      rev = "e652d62451dc67a9c6bc16c00ccbc38fed3373dd";
      fetchSubmodules = false;
      deepClone = false;
      leaveDotGit = false;
      sha256 = "182hqn4kbh0vmnbhj7nrqx2lypkddd6appp5y4kqinnw8dmpdyqx";
    };
  };
  qvpersonal = {
    pname = "qvpersonal";
    version = "nightly-2021-10-06";
    src = fetchurl {
      url = "https://github.com/Shadowsocks-NET/QvStaticBuild/releases/download/nightly-2021-10-06/qv2ray-static-bin-nightly-2021-10-06-archlinux-x86_64.tar.zst";
      sha256 = "0pqvwdjnym277wahb2qj16cf53x7dwlnij6fl5rhmgpvrmblf7xb";
    };
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
      sha256 = "020gz8z4sn60kv9jasq682s8abmdlz841fwvf7zc86ksb79z4m99";
    };
    vendorSha256 = "sha256-55Zu1g+pwTt6dU1QloxfFkG2dbnK5gg84WvRhz2ND3M=";
  };
  smartdns-china-list = {
    pname = "smartdns-china-list";
    version = "ab59165e481e9f2192ab357c32778482e55b7650";
    src = fetchgit {
      url = "https://github.com/felixonmars/dnsmasq-china-list";
      rev = "ab59165e481e9f2192ab357c32778482e55b7650";
      fetchSubmodules = false;
      deepClone = false;
      leaveDotGit = false;
      sha256 = "0l6xxh11pnnj2acmlz9g9nc05mzsz04aklrshksllzf4hw95avar";
    };
  };
  tslib = {
    pname = "tslib";
    version = "1.22";
    src = fetchgit {
      url = "https://github.com/libts/tslib";
      rev = "1.22";
      fetchSubmodules = false;
      deepClone = false;
      leaveDotGit = false;
      sha256 = "197p6vy539wvfrv23agbvmay4rjya1jnisi46llm0nx4cvqh48by";
    };
  };
  v2ray-domain-list-community = {
    pname = "v2ray-domain-list-community";
    version = "7c694390e156c8dcee34991b6c6b30905bef9f1f";
    src = fetchgit {
      url = "https://github.com/v2fly/domain-list-community";
      rev = "7c694390e156c8dcee34991b6c6b30905bef9f1f";
      fetchSubmodules = false;
      deepClone = false;
      leaveDotGit = false;
      sha256 = "1g2pl3scww91hi3v3qq4hqbmyhng8zhwgyq0ms0bkaxc0yjqwx43";
    };
    vendorSha256 = "sha256-JuLU9v1ukVfAEtz07tGk66st1+sO4SBz83BlK3IPQwU=";
  };
  v2ray-geoip = {
    pname = "v2ray-geoip";
    version = "34511623021ee5723ed449c7fc5744455dbfca2e";
    src = fetchgit {
      url = "https://github.com/v2fly/geoip";
      rev = "34511623021ee5723ed449c7fc5744455dbfca2e";
      fetchSubmodules = false;
      deepClone = false;
      leaveDotGit = false;
      sha256 = "18s5ivwsgzmy47j6b2dbb9ksm8akrjl92ijps06y114hx9i4n9ds";
    };
  };
  wemeet = {
    pname = "wemeet";
    version = "2.8.0.0";
    src = fetchurl {
      url = "https://updatecdn.meeting.qq.com/ad878a99-76c4-4058-ae83-22ee948cce98/TencentMeeting_0300000000_2.8.0.0_x86_64.publish.deb";
      sha256 = "1gzw9srch9il7cx4x8hribiq3akgrv6590qk9xlrc0c709mm1cx6";
    };
  };
}
