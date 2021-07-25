# This file was generated by nvfetcher, please do not modify it manually.
{ fetchgit, fetchurl }:
{
  auth-thu = {
    pname = "auth-thu";
    version = "v2.1.2";
    src = fetchgit {
      url = "https://github.com/z4yx/GoAuthing";
      rev = "v2.1.2";
      fetchSubmodules = false;
      deepClone = false;
      leaveDotGit = false;
      sha256 = "01jll7ll3k3p1cm1vcz40j17g7zhdfpljyiwrrfhi6bdhpglpw7l";
    };
    vendorSha256 = "sha256-SCLbX9NqMLBNSBHC3a921b8+3Vy7VHjUcFHbjidwQ+c=";
  };
  chasquid = {
    pname = "chasquid";
    version = "v1.7";
    src = fetchgit {
      url = "https://github.com/albertito/chasquid";
      rev = "v1.7";
      fetchSubmodules = false;
      deepClone = false;
      leaveDotGit = false;
      sha256 = "1i2rwsjqsk9q92nmjlna3agx782v3vhw0a9s55i14vd0794mm8vc";
    };
    vendorSha256 = "sha256-1H1zTRzX6a4mBSHIJvLeVC9GIKE8qUvwbgfRw297vq4=";
  };
  k0sctl = {
    pname = "k0sctl";
    version = "v0.9.0";
    src = fetchgit {
      url = "https://github.com/k0sproject/k0sctl";
      rev = "v0.9.0";
      fetchSubmodules = false;
      deepClone = false;
      leaveDotGit = false;
      sha256 = "06z9bgapb1mjmnh08z7d0ivy7ldrqz04w3swvqrls5fyfzcz2vk9";
    };
  };
  ko = {
    pname = "ko";
    version = "v0.8.3";
    src = fetchgit {
      url = "https://github.com/google/ko";
      rev = "v0.8.3";
      fetchSubmodules = false;
      deepClone = false;
      leaveDotGit = false;
      sha256 = "1ccw09ghpnxsv88mp6y6amyif95hrq004m8x3albbxda77whxb1q";
    };
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
  qv2ray = {
    pname = "qv2ray";
    version = "d19ba329fcb72dd2a0a2cfc6bb7855110fda375f";
    src = fetchgit {
      url = "https://github.com/Qv2ray/Qv2ray";
      rev = "d19ba329fcb72dd2a0a2cfc6bb7855110fda375f";
      fetchSubmodules = true;
      deepClone = false;
      leaveDotGit = false;
      sha256 = "0jbrywwvqcn9sbk9vxwvdjn1grnyspymrzvbfx6cj87mlzaqsmj8";
    };
  };
  qv2ray-plugin-ss = {
    pname = "qv2ray-plugin-ss";
    version = "b8a497ed610b968eab0dc0a47e87ded63a2d64a9";
    src = fetchgit {
      url = "https://github.com/Qv2ray/QvPlugin-SS";
      rev = "b8a497ed610b968eab0dc0a47e87ded63a2d64a9";
      fetchSubmodules = true;
      deepClone = false;
      leaveDotGit = false;
      sha256 = "1acnqvfwgxjn2d3gbbkd3dp1vw7j53a7flwwn4mn93l9y6y0n72r";
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
    version = "10b36191bc1092d2f975ffe89cfd221c0915ff4c";
    src = fetchgit {
      url = "https://github.com/felixonmars/dnsmasq-china-list";
      rev = "10b36191bc1092d2f975ffe89cfd221c0915ff4c";
      fetchSubmodules = false;
      deepClone = false;
      leaveDotGit = false;
      sha256 = "0rvi6ryzdkknv3bbhimjhkpwn5akf5h5ah2h1nvwia6m7qr3i56j";
    };
  };
  traefik-certs-dumper = {
    pname = "traefik-certs-dumper";
    version = "29d75cac576a375c61d1c5a46aff85764a62c31f";
    src = fetchgit {
      url = "https://github.com/ldez/traefik-certs-dumper";
      rev = "29d75cac576a375c61d1c5a46aff85764a62c31f";
      fetchSubmodules = false;
      deepClone = false;
      leaveDotGit = false;
      sha256 = "01cn80v47pbl6fm9286k52rpya9v5k549bd5a2b54bl1252vnxxz";
    };
    vendorSha256 = "sha256-Z2+Eo6ZBL5z88k64B5HfQ9WT4/gOypw797M3PnYoNzQ=";
  };
  v2ray-domain-list-community = {
    pname = "v2ray-domain-list-community";
    version = "26fa3e24ba8e6cafb1eb90206a1f9fe0532329a3";
    src = fetchgit {
      url = "https://github.com/v2fly/domain-list-community";
      rev = "26fa3e24ba8e6cafb1eb90206a1f9fe0532329a3";
      fetchSubmodules = false;
      deepClone = false;
      leaveDotGit = false;
      sha256 = "0zyf5lj2h2ypf2bgz21jcjnvih37b750kih4dg65rpx9v8i42f6z";
    };
    vendorSha256 = "sha256-vNLhCI7C+Y/MqcH0MhTUICGnbmYQQCPypZmUVPZhA7Q=";
  };
  v2ray-geoip = {
    pname = "v2ray-geoip";
    version = "8304cc2a57a68254ff805d0d0bfbba434ebb9033";
    src = fetchgit {
      url = "https://github.com/v2fly/geoip";
      rev = "8304cc2a57a68254ff805d0d0bfbba434ebb9033";
      fetchSubmodules = false;
      deepClone = false;
      leaveDotGit = false;
      sha256 = "03sqf1jzdmjhg138izdc7rvl5xwhkfp1yqca492pmv5wb9rp091z";
    };
  };
}
