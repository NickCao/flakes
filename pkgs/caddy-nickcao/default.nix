{ buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "caddy";
  version = "2.7.1";

  src = fetchFromGitHub {
    owner = "NickCao";
    repo = "caddy";
    rev = "0af7855c1d143eaf2eec69f090b513159193c432";
    hash = "sha256-HVDIpP9lkhJGtkQIRgLfgn0/3HdUKM8ouLGEIrpklyE=";
  };

  vendorHash = "sha256-LLuw6SOk6k93RbODY8x4T6ElwCXmTkd/Az/Ubt8KRyo=";

  subPackages = [ "cmd/caddy" ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/caddyserver/caddy/v2.CustomVersion=${version}"
  ];
}
