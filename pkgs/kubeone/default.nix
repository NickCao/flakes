{ buildGoModule, fetchFromGitHub, lib }:

buildGoModule rec {
  pname = "kubeone";
  version = "2021-03-23";

  src = fetchFromGitHub {
    owner = "kubermatic";
    repo = "kubeone";
    rev = "51a3729d1f5868e740861bec9fb6b8083bebf6ec"; # tags/v*
    sha256 = "1abm7735c4pjv31pfggkvia7br19zbhjpp2w0n5zckwrjm9hxns6";
  };

  vendorSha256 = "sha256-VvO5YnDofdEku9+RC6PPHWSZY8qZt9N3JNzlm5omNAc=";
  subPackages = [ "." ];

  meta = with lib; {
    description = "Kubermatic KubeOne automate cluster operations on all your cloud, on-prem, edge, and IoT environments.";
    homepage = "https://github.com/kubermatic/kubeone";
    license = licenses.asl20;
  };
}
