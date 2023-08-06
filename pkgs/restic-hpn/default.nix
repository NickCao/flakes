{ restic }:
restic.overrideAttrs (attrs: {
  patches = attrs.patches ++ [ ./0001-sftp-raise-packet-size-and-concurrency.patch ];
})
