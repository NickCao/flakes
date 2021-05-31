# This file was generated by nvfetcher, please do not modify it manually.
{ fetchgit, fetchurl }:
{
  auth-thu = {
    pname = "auth-thu";
    version = "v2.0.3";
    src = fetchgit {
      url = "https://github.com/z4yx/GoAuthing";
      rev = "v2.0.3";
      fetchSubmodules = false;
      deepClone = false;
      leaveDotGit = false;
      sha256 = "1z1anpp16d01ncp2bg1ahnyn0707xnavhbaqhddjhzw78zsh120q";
    };
  };
  butane = {
    pname = "butane";
    version = "v0.11.0";
    src = fetchgit {
      url = "https://github.com/coreos/butane";
      rev = "v0.11.0";
      fetchSubmodules = false;
      deepClone = false;
      leaveDotGit = false;
      sha256 = "1s4rkq7mj1lyi8h47jyfy3qygfxhrmpihdy8rcnn55gcy04lm0qc";
    };
  };
  k0sctl = {
    pname = "k0sctl";
    version = "v0.8.4";
    src = fetchgit {
      url = "https://github.com/k0sproject/k0sctl";
      rev = "v0.8.4";
      fetchSubmodules = false;
      deepClone = false;
      leaveDotGit = false;
      sha256 = "08k0aa73kb4hs4zl8a2nmasag0czmppb2r0s1afj287c2a4ynw73";
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
  kubeone = {
    pname = "kubeone";
    version = "v1.2.1";
    src = fetchgit {
      url = "https://github.com/kubermatic/kubeone";
      rev = "v1.2.1";
      fetchSubmodules = false;
      deepClone = false;
      leaveDotGit = false;
      sha256 = "1abm7735c4pjv31pfggkvia7br19zbhjpp2w0n5zckwrjm9hxns6";
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
  };
  smartdns-china-list = {
    pname = "smartdns-china-list";
    version = "3aa5c845f4adbe8801c786e0a38125ba5d689f12";
    src = fetchgit {
      url = "https://github.com/felixonmars/dnsmasq-china-list";
      rev = "3aa5c845f4adbe8801c786e0a38125ba5d689f12";
      fetchSubmodules = false;
      deepClone = false;
      leaveDotGit = false;
      sha256 = "036x2s34j0c3m998gl00p510z958qacvxq8cwmln10n5ka9i367k";
    };
    
  };
  v2ray-domain-list-community = {
    pname = "v2ray-domain-list-community";
    version = "9427929786bce59bbaf9919eced085e48a302ed9";
    src = fetchgit {
      url = "https://github.com/v2fly/domain-list-community";
      rev = "9427929786bce59bbaf9919eced085e48a302ed9";
      fetchSubmodules = false;
      deepClone = false;
      leaveDotGit = false;
      sha256 = "0jf8r8msh36zjbybblwzh7wwq4y3i8y64nshr5yca725l1q1qn3k";
    };
    
  };
  v2ray-geoip = {
    pname = "v2ray-geoip";
    version = "e4101ba35587a56ced6ad8f9fdee76cbbf237c22";
    src = fetchgit {
      url = "https://github.com/v2fly/geoip";
      rev = "e4101ba35587a56ced6ad8f9fdee76cbbf237c22";
      fetchSubmodules = false;
      deepClone = false;
      leaveDotGit = false;
      sha256 = "0bin6bj8sll024cyssikbxrgzyv4214yz6a5xmqcfwd5b43wc6z7";
    };
  };
}
