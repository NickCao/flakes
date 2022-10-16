{ iwd, ell }:

iwd.override {
  ell = ell.overrideAttrs (_: {
    postPatch = ''
      substituteInPlace ell/tls-suites.c \
        --replace 'params->prime_len < 192' 'params->prime_len < 128'
    '';
  });
}
