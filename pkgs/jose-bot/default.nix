{ python3Packages
, fetchFromGitHub
}:

with python3Packages;
buildPythonApplication rec {
  pname = "jose-bot";
  version = "unstable-2023-06-14";

  format = "pyproject";

  src = fetchFromGitHub {
    owner = "ShadowRZ";
    repo = pname;
    rev = "958a175eb5b61c8a22504b11c50c9d7bf96018b7";
    hash = "sha256-kYChKS6W/jNQhbrsVWF91/Uf6lLViyqnn6KjJn6Innw=";
  };

  nativeBuildInputs = [
    setuptools
  ];

  propagatedBuildInputs = [
    matrix-nio
    xxhash
    pyyaml
  ];
}
