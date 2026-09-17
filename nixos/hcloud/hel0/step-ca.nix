{
  config,
  pkgs,
  ...
}:
{
  sops.secrets = {
    "step-ca/root_ca.crt" = {
      owner = config.users.users.step-ca.name;
    };
    "step-ca/intermediate_ca.crt" = {
      owner = config.users.users.step-ca.name;
    };
    "step-ca/intermediate_ca_key" = {
      owner = config.users.users.step-ca.name;
    };
    "step-ca/password" = { };
  };
  services.step-ca = {
    enable = true;
    address = "[::]";
    port = 8443;
    intermediatePasswordFile = config.sops.secrets."step-ca/password".path;
    settings = {
      root = config.sops.secrets."step-ca/root_ca.crt".path;
      crt = config.sops.secrets."step-ca/intermediate_ca.crt".path;
      key = config.sops.secrets."step-ca/intermediate_ca_key".path;
      dnsNames = [ "ca.nichi.co" ];
      logger = {
        format = "text";
      };
      db = {
        type = "badgerv2";
        dataSource = "/var/lib/step-ca/db";
      };
      tls = {
        cipherSuites = [
          "TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256"
          "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256"
        ];
        minVersion = 1.2;
        maxVersion = 1.3;
        renegotiation = false;
      };
      authority = {
        provisioners = [
          {
            type = "OIDC";
            name = "keyclock";
            clientID = "step-ca";
            # In the context of step-ca, the client "secret" is not actually a secret and is available
            # via the CA's /provisioners configuration endpoint, because every step client needs to use it locally.
            # Reference: https://smallstep.com/docs/step-ca/provisioners/#oauthoidc-single-sign-on
            clientSecret = "9fVRwZbRgCeOOy3rdabUeG22f1N2t9j1Nh6TfcsMn8zxAtfZeAIjvpL5HYtCdcXCavJ7OjvLglHUF3AcYKMDFr";
            configurationEndpoint = "https://id.nichi.co/realms/nichi/.well-known/openid-configuration";
            options = {
              x509.templateFile = pkgs.writeText "" ''
                {
                  "sans": {{ toJson .SANs }},
                {{- if typeIs "*rsa.PublicKey" .Insecure.CR.PublicKey }}
                  "keyUsage": ["keyEncipherment", "digitalSignature"],
                {{- else }}
                  "keyUsage": ["digitalSignature"],
                {{- end }}
                  "extKeyUsage": ["clientAuth"]
                }
              '';
            };
          }
        ];
        policy = {
          x509 = {
            allow = {
              email = [
                "@nichi.co"
              ];
              uri = [
                "id.nichi.co"
              ];
              allowWildcardNames = false;
            };
          };
        };
      };
    };
  };
}
# step ca bootstrap --ca-url https://ca.nichi.co:8443 --fingerprint 1653b77b96c657f8a4d793238a0abf5d4b4dce76ac710fbfa08092c640f73697
