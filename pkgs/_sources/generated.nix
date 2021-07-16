# This file was generated by nvfetcher, please do not modify it manually.
{ fetchgit, fetchurl }:
{
  auth-thu = {
    pname = "auth-thu";
    version = "v2.1.1";
    src = fetchgit {
      url = "https://github.com/z4yx/GoAuthing";
      rev = "v2.1.1";
      fetchSubmodules = false;
      deepClone = false;
      leaveDotGit = false;
      sha256 = "0v1id1aqklkmph1l87zwj4wbcvbkn25b0mnk0cs2n45b6w37cld3";
    };
    
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
  kubeone = {
    pname = "kubeone";
    version = "v1.2.3";
    src = fetchgit {
      url = "https://github.com/kubermatic/kubeone";
      rev = "v1.2.3";
      fetchSubmodules = false;
      deepClone = false;
      leaveDotGit = false;
      sha256 = "1fvcjllirg5vr2d1lgm4s4zq42k1xsivqpl32yzbdyq4zkqw92d0";
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
  qvpersonal = {
    pname = "qvpersonal";
    version = "a24db9b94a74d90d5b5aa70dbbdd220702954a1d";
    src = fetchgit {
      url = "https://github.com/moodyhunter/QvPersonal";
      rev = "a24db9b94a74d90d5b5aa70dbbdd220702954a1d";
      fetchSubmodules = false;
      deepClone = false;
      leaveDotGit = false;
      sha256 = "023v7ai1n9gvbavaswvh2g9lg9vsw4iv7dgc0fjhi7vhnlfapchg";
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
    version = "104b0699fb224bb893d6ec393b449c756c8b1207";
    src = fetchgit {
      url = "https://github.com/felixonmars/dnsmasq-china-list";
      rev = "104b0699fb224bb893d6ec393b449c756c8b1207";
      fetchSubmodules = false;
      deepClone = false;
      leaveDotGit = false;
      sha256 = "1ckn6rr53ggas5bm1fichl4dy5arqasj75xkrkgcfhwq85kh43b3";
    };
    
  };
  v2ray-domain-list-community = {
    pname = "v2ray-domain-list-community";
    version = "2f54584288b35891e09b6d6b3062b836cf4c3f50";
    src = fetchgit {
      url = "https://github.com/v2fly/domain-list-community";
      rev = "2f54584288b35891e09b6d6b3062b836cf4c3f50";
      fetchSubmodules = false;
      deepClone = false;
      leaveDotGit = false;
      sha256 = "157iy3szlfvq4ii6wl7hlagydckxf5d09zkifjqf0l24897mv67v";
    };
    
  };
  v2ray-geoip = {
    pname = "v2ray-geoip";
    version = "2ecda1c835aed03c6476107db95c4db9fb4fe6f4";
    src = fetchgit {
      url = "https://github.com/v2fly/geoip";
      rev = "2ecda1c835aed03c6476107db95c4db9fb4fe6f4";
      fetchSubmodules = false;
      deepClone = false;
      leaveDotGit = false;
      sha256 = "101w4050nvvg5abrv5fycpc6gic7lviw01kkklsb34z7arywy0jc";
    };
    
  };
}
