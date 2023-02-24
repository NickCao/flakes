# This file was generated by nvfetcher, please do not modify it manually.
{ fetchgit, fetchurl, fetchFromGitHub, dockerTools }:
{
  bird-babel-rtt = {
    pname = "bird-babel-rtt";
    version = "b0b12f37388e59b4456119d3a90d4ff69622d698";
    src = fetchFromGitHub ({
      owner = "NickCao";
      repo = "bird";
      rev = "b0b12f37388e59b4456119d3a90d4ff69622d698";
      fetchSubmodules = false;
      sha256 = "sha256-9Ufu6gGDVMZHoxZdqc2khNBsrvBcS+18IIYIcsVsdsY=";
    });
    date = "2023-02-14";
  };
  fcitx5-pinyin-zhwiki = {
    pname = "fcitx5-pinyin-zhwiki";
    version = "20230128";
    src = fetchurl {
      url = "https://github.com/felixonmars/fcitx5-pinyin-zhwiki/releases/download/0.2.4/zhwiki-20230128.dict";
      sha256 = "sha256-SFSNwsyE9W9pCIKlu+8pGVVNdNn6MITA4x7meicbUyQ=";
    };
  };
  neondb = {
    pname = "neondb";
    version = "9f906ff2369ac9cea4a92245d88e5a70cf5f7e02";
    src = fetchFromGitHub ({
      owner = "neondatabase";
      repo = "neon";
      rev = "9f906ff2369ac9cea4a92245d88e5a70cf5f7e02";
      fetchSubmodules = true;
      sha256 = "sha256-PtR8beyXuFPcvqKQ3XdfI+WG/Mtwc3uPTzzOx56/0m0=";
    });
    cargoLock."Cargo.lock" = {
      lockFile = ./neondb-9f906ff2369ac9cea4a92245d88e5a70cf5f7e02/Cargo.lock;
      outputHashes = {
        "heapless-0.8.0" = "sha256-phCls7RQZV0uYhDEp0GIphTBw0cXcurpqvzQCAionhs=";
        "postgres-0.19.4" = "sha256-rpboUP7K+2XdcRr80T4u1jKIj788bqz2usSqWmZDB3E=";
        "tokio-tar-0.3.0" = "sha256-ktQOFE6yItvP77oVe6bT1hwXjdvPmvJVYxYF4FS6b3I=";
      };
    };
    date = "2023-02-23";
  };
  wemeet = {
    pname = "wemeet";
    version = "3.12.0.400";
    src = fetchurl {
      url = "https://updatecdn.meeting.qq.com/cos/e078bf97365540d9f0ff063f93372a9c/TencentMeeting_0300000000_3.12.0.400_x86_64_default.publish.deb";
      sha256 = "sha256-NN09Sm8IepV0tkosqC3pSor4/db4iF11XcGAuN/iOpM=";
    };
  };
}
