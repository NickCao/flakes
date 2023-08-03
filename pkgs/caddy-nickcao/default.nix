{ buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "caddy";
  version = "2.7.1";

  src = fetchFromGitHub {
    owner = "NickCao";
    repo = "caddy";
    rev = "e5b9313f6f8adecce3f7dc93a3954b8d24f4138a";
    hash = "sha256-lfF+fqwdzy1AMfEtigWikep7zmBLzCnYDV6vMQ6w74I=";
  };

  vendorHash = "sha256-b8UoEPRG65HOTV8SA+lp4xyxKqVSJj/JwnIMXxxEan4=";

  subPackages = [ "cmd/caddy" ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/caddyserver/caddy/v2.CustomVersion=${version}"
  ];
}
