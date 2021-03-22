{ buildGoModule, fetchFromGitHub, lib }:

buildGoModule rec {
  pname = "kubeone";
  version = "2021-03-17";

  src = fetchFromGitHub {
    owner = "kubermatic";
    repo = "kubeone";
    rev = "2254855f7d199df7c32ab5ff93d01221df52019b"; # tags/v*
    sha256 = "0ywrq212yy3z2lvm7srscklhs7a7x8yn2f3110v48k8s74x4h97l";
  };

  vendorSha256 = "sha256-VvO5YnDofdEku9+RC6PPHWSZY8qZt9N3JNzlm5omNAc=";
  subPackages = [ "." ];

  meta = with lib; {
    description = "Kubermatic KubeOne automate cluster operations on all your cloud, on-prem, edge, and IoT environments.";
    homepage = "https://github.com/kubermatic/kubeone";
    license = licenses.asl20;
  };
}
