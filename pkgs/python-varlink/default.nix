{ python3Packages, lib }:

with python3Packages;
buildPythonPackage rec {
  pname = "varlink";
  version = "30.3.1";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-YxHUpnxrKIXr/ToNqhW7Us3SqfAlDz4g+5s9D5zP1r8=";
  };

  buildInputs = [ setuptools_scm ];
  doCheck = false;

  meta = with lib; {
    homepage = "https://github.com/varlink/python";
    description = "Python implementation of the Varlink protocol";
    license = licenses.asl20;
  };
}
