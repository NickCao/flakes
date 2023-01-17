{ lib
, buildGoModule
, fetchFromGitHub
, openldap
}:

buildGoModule rec {
  pname = "glauth";
  version = "2.2.0-RC1";

  src = fetchFromGitHub {
    owner = pname;
    repo = pname;
    rev = "v${version}";
    hash = "sha256-fPEBSEmlFYoe4PGfs7x26GvVlLZhiPvwiUgXwhlrXLk=";
  };

  vendorHash = "sha256-8xjnNjkHI5QrfgJmAgRb2izMkgATdGzSesnWGOvmomY=";

  sourceRoot = "source/v2";
  subPackages = [ "." ];
  doCheck = false;
}
