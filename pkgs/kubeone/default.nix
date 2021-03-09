{ buildGoModule, fetchFromGitHub, lib }:

buildGoModule rec {
  pname = "kubeone";
  version = "2021-03-08";

  src = fetchFromGitHub {
    owner = "kubermatic";
    repo = "kubeone";
    rev = "1e5f11a19267138d5f580ee16011f83e32cc32e7"; # tags/v*
    sha256 = "1f9d5ww2v1yix3c76dw52rj6h1qrjghgspsxiy9l01wbzxqq1brj";
  };

  vendorSha256 = "sha256-VvO5YnDofdEku9+RC6PPHWSZY8qZt9N3JNzlm5omNAc=";
  subPackages = [ "." ];

  meta = with lib; {
    description = "Kubermatic KubeOne automate cluster operations on all your cloud, on-prem, edge, and IoT environments.";
    homepage = "https://github.com/kubermatic/kubeone";
    license = licenses.asl20;
  };
}
