# This file was generated by nvfetcher, please do not modify it manually.
{ fetchgit, fetchurl, fetchFromGitHub, dockerTools }:
{
  bird-babel-rtt = {
    pname = "bird-babel-rtt";
    version = "e508ca76a198f633e1720466e1084333ae8b2742";
    src = fetchFromGitHub ({
      owner = "NickCao";
      repo = "bird";
      rev = "e508ca76a198f633e1720466e1084333ae8b2742";
      fetchSubmodules = false;
      sha256 = "sha256-JdxWSXsPUPNHZxFxdOa8Ogui6Xf2Ife5UgWSLO6Lwrc=";
    });
    date = "2022-12-12";
  };
  fcitx5-pinyin-zhwiki = {
    pname = "fcitx5-pinyin-zhwiki";
    version = "20221230";
    src = fetchurl {
      url = "https://github.com/felixonmars/fcitx5-pinyin-zhwiki/releases/download/0.2.4/zhwiki-20221230.dict";
      sha256 = "sha256-Mu06WNiL73YWVLbFyZNoDBJONvRB3H0PNeAZb09gx0o=";
    };
  };
  neondb = {
    pname = "neondb";
    version = "95bf19b85a06b27a7fc3118dee03d48648efab15";
    src = fetchFromGitHub ({
      owner = "neondatabase";
      repo = "neon";
      rev = "95bf19b85a06b27a7fc3118dee03d48648efab15";
      fetchSubmodules = true;
      sha256 = "sha256-PUwbYQfLakhDNU4hDn49YJvVs9HvY7a+W3TQnlchEgM=";
    });
    cargoLock."Cargo.lock" = {
      lockFile = ./neondb-95bf19b85a06b27a7fc3118dee03d48648efab15/Cargo.lock;
      outputHashes = {
        "postgres-0.19.4" = "sha256-rpboUP7K+2XdcRr80T4u1jKIj788bqz2usSqWmZDB3E=";
        "amplify_num-0.4.1" = "sha256-7raFT2CLEz4bza0CCSnA0EEnIRJ/neRvXp8Ji4l0AfA=";
        "tokio-tar-0.3.0" = "sha256-ktQOFE6yItvP77oVe6bT1hwXjdvPmvJVYxYF4FS6b3I=";
      };
    };
    date = "2023-01-10";
  };
  riscv-openocd = {
    pname = "riscv-openocd";
    version = "43ea20dfbb6c815004a51106a3b2009d7f6c4940";
    src = fetchFromGitHub ({
      owner = "riscv";
      repo = "riscv-openocd";
      rev = "43ea20dfbb6c815004a51106a3b2009d7f6c4940";
      fetchSubmodules = true;
      sha256 = "sha256-mupLfeTg/zeErHSwwgMaKmxbi/X0TvXm1RlEOgkgyJk=";
    });
    date = "2023-01-04";
  };
  smartdns-china-list = {
    pname = "smartdns-china-list";
    version = "75c54c2d3d5e3bb1b7e490c9ff27e99e7c28cd27";
    src = fetchFromGitHub ({
      owner = "felixonmars";
      repo = "dnsmasq-china-list";
      rev = "75c54c2d3d5e3bb1b7e490c9ff27e99e7c28cd27";
      fetchSubmodules = false;
      sha256 = "sha256-gBMvYgK03psZtfLDzwGXcWY6P4Cg5L8YD79cRAovQUc=";
    });
    date = "2023-01-10";
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
