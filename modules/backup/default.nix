{ config, pkgs, lib, ... }:
let
  cfg = config.environment.backup;
in
{

  options.environment.backup = {
    enable = lib.mkEnableOption "backup";
  };

  config = lib.mkIf cfg.enable {

    environment.etc."rclone.conf".source = (pkgs.formats.ini { }).generate "rclone.conf" {
      rsyncnet = rec {
        type = "sftp";
        host = "${user}.rsync.net";
        user = "fm1622";
        key_file = config.sops.secrets.restic-keys.path;
        # see https://forum.rclone.org/t/rclone-fails-ssh-handshakes-with-rsync-nets-sftp-when-a-known-hosts-file-is-specified/29206
        known_hosts_file = pkgs.writeText "known_hosts" ''
          ${host} ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBNKxjzXzYdLwYoXcT/lRlxNzfHdGkr0pZDLk1tiPvLnbec1st3UjYq8HgYE1c/ko0VqINCR1uarlObpKpmazVHc=
          ${host} ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINdUkGe6kKn5ssz4WRZKjcws0InbQqZayenzk9obmP1z
        '';
        shell_type = "unix";
        md5sum_command = "md5 -r";
        sha1sum_command = "sha1 -r";
        chunk_size = "255k";
        concurrency = 128;
      };
    };

    sops.secrets = {
      restic-repo = { sopsFile = ./secrets.yaml; };
      restic-pass = { sopsFile = ./secrets.yaml; };
      restic-envs = { sopsFile = ./secrets.yaml; };
      restic-keys = { sopsFile = ./secrets.yaml; };
    };

    environment.systemPackages = [ pkgs.restic ];
  };

}
