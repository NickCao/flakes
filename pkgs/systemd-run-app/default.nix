{
  writeShellApplication,
  openssl,
  coreutils,
}:
writeShellApplication {
  name = "systemd-run-app";
  text = ''
    name=$(${coreutils}/bin/basename "$1")
    id=$(${openssl}/bin/openssl rand -hex 4)
    exec systemd-run \
      --user \
      --scope \
      --unit "$name-$id" \
      --slice=app \
      --same-dir \
      --collect \
      --property PartOf=graphical-session.target \
      --property After=graphical-session.target \
      -- "$@"
  '';
}
