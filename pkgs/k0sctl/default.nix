{ buildGoModule, fetchFromGitHub, lib }:

buildGoModule rec {
  pname = "k0sctl";
  version = "2021-04-08";

  src = fetchFromGitHub {
    owner = "k0sproject";
    repo = "k0sctl";
    rev = "a956fc759418c35aaf8d6170d5447d60e521e929"; # tags/v*
    sha256 = "03w2l831awscp4wg17knxd2c4qygsl6m2lm6741dr5sbqmkbw1zn";
  };

  vendorSha256 = "sha256-tdvLprHDDWbI5qMaDRp+tlpyUknL6o885Kve8i8Mukg=";
  subPackages = [ "." ];

  meta = with lib; {
    homepage = "https://github.com/k0sproject/k0sctl";
    license = licenses.asl20;
  };
}
