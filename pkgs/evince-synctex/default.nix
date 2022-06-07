{ source, python3Packages }: 

python3Packages.buildPythonApplication {
  inherit (source) pname version src;
  propagatedBuildInputs = with python3Packages; [ dbus-python ];
}
