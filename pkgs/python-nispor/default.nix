{ stdenv, python3Packages, nispor, lib }:

with python3Packages;
buildPythonPackage rec {
  pname = "nispor";
  version = "1.0.1";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-fO9xTff8M0pVK3fCGz2npY2DR/M5kdW2ugkEjUxKFVo=";
  };

  postPatch = ''
    substituteInPlace nispor/clib_wrapper.py --replace 'find_library("nispor")' '"${nispor}/lib/libnispor.so"'
  '';

  meta = with lib; {
    homepage = "https://github.com/nispor/nispor/";
    description = "Python binding of Nispor";
    license = licenses.asl20;
  };
}
