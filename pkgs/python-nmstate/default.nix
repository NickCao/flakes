{ python3Packages, python-varlink, python-nispor, networkmanager, lib }:

with python3Packages;
buildPythonPackage rec {
  pname = "nmstate";
  version = "1.0.0";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-hkF8GFEwllR4P4uP4DdP7SRLMi+Tm5Nd7UIFe3rkldk=";
  };

  doCheck = false;

  propagatedBuildInputs = [ python-varlink pyyaml python-nispor jsonschema pygobject3 ];

  meta = with lib; {
    homepage = "https://www.nmstate.io/";
    description = "Declarative network manager API";
    license = licenses.lgpl21Plus;
  };
}
