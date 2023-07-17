{ openssh
, keyutils
}:

openssh.overrideAttrs (attrs: {
  patches = attrs.patches ++ [ ./0001-read-fido2-pin-with-request_key.patch ];
  buildInputs = attrs.buildInputs ++ [ keyutils ];
  env.LDFLAGS = "-lkeyutils";
  doCheck = false;
})
