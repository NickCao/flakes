{ source, python3Packages }:

python3Packages.buildPythonApplication {
  inherit (source) pname version src;
  patches = [ ./poll.patch ];
  propagatedBuildInputs = with python3Packages; [ dbus-python pygobject3 ];
}
