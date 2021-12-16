{ source, buildGoModule, fetchFromGitHub, lib }:
buildGoModule rec {
  inherit (source) pname version src vendorSha256;
  subPackages = [ "." ];
  postInstall = ''
    # mv $out/bin/cli $out/bin/auth-thu
  '';
  meta = with lib; {
    description = "Kine is an etcdshim that translates etcd API to sqlite, Postgres, Mysql, and dqlite";
    homepage = "https://github.com/k3s-io/kine";
    license = licenses.asl20;
  };
}
