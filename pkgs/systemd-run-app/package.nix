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
      --unit "$name-$id" \
      --slice=app \
      --collect \
      --property Type=exec \
      --property ExitType=cgroup \
      --property PartOf=graphical-session.target \
      --property After=graphical-session.target \
      -- "$@"
  '';
}
