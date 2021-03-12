{ buildGoModule, fetchFromGitHub, lib }:

buildGoModule rec {
  pname = "kubeone";
  version = "2021-03-12";

  src = fetchFromGitHub {
    owner = "kubermatic";
    repo = "kubeone";
    rev = "fde1f267769e04acc07bbdb94c09b0d6a18ea4cc"; # tags/v*
    sha256 = "06ib79kgd7kc68s62cqqx9s6cklp3jylfqmjcnhlf04llkkyc2na";
  };

  vendorSha256 = "sha256-VvO5YnDofdEku9+RC6PPHWSZY8qZt9N3JNzlm5omNAc=";
  subPackages = [ "." ];

  meta = with lib; {
    description = "Kubermatic KubeOne automate cluster operations on all your cloud, on-prem, edge, and IoT environments.";
    homepage = "https://github.com/kubermatic/kubeone";
    license = licenses.asl20;
  };
}
