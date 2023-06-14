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
    rev = "cef9a8ce1bef27b1ca9370e11f4460981c392102";
    hash = "sha256-OU58G5iS6kQIQjmcZKk1hK3Tj0orZeDHAt9wUQ69NT8=";
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
