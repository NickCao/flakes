{ buildGoModule, fetchFromGitHub, lib }:

buildGoModule rec {
  pname = "kubeone";
  version = "2021-02-17";

  src = fetchFromGitHub {
    owner = "kubermatic";
    repo = "kubeone";
    rev = "ed0282cc587cfc5313c92db2384605827981253e"; # tags/v*
    sha256 = "03r8ajqxhza3gqnd1xr9hsf8wqsibzhg32c7jp7kp7kw5yfmq8c6";
  };

  vendorSha256 = "sha256-VvO5YnDofdEku9+RC6PPHWSZY8qZt9N3JNzlm5omNAc=";
  subPackages = [ "." ];

  meta = with lib; {
    description = "Kubermatic KubeOne automate cluster operations on all your cloud, on-prem, edge, and IoT environments.";
    homepage = "https://github.com/kubermatic/kubeone";
    license = licenses.asl20;
  };
}
