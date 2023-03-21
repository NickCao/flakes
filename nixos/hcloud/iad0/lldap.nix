{ pkgs, inputs, ... }:
let
  config = {
    ldap_host = "127.0.0.1";
    ldap_port = 3890;
    http_host = "127.0.0.1";
    http_port = 17170;
    ldap_base_dn = "dc=nichi,dc=co";
    ldap_user_dn = "nickcao";
    database_url = "sqlite:///var/lib/lldap/users.db?mode=rwc";
    key_file = "/var/lib/lldap/key";
  };
  configFile = (pkgs.formats.toml { }).generate "config.toml" config;
in
{

  cloud.services.lldap.config = {
    StateDirectory = "lldap";
    ExecStartPre = [
      "${pkgs.openssl}/bin/openssl rand -hex -out \${STATE_DIRECTORY}/jwt 32"
      "${pkgs.openssl}/bin/openssl rand -hex -out \${STATE_DIRECTORY}/pass 32"
    ];
    Environment = [
      "LLDAP_JWT_SECRET_FILE=/var/lib/lldap/jwt"
      "LLDAP_LDAP_USER_PASS_FILE=/var/lib/lldap/pass"
    ];
    ExecStart = ''
      ${inputs.lldap.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/lldap run \
        --config-file ${configFile}
    '';
  };

  services.traefik = {
    staticConfigOptions = {
      entryPoints.ldap.address = ":636";
    };
    dynamicConfigOptions = {
      http = {
        routers.lldap = {
          rule = "Host(`id.nichi.co`)";
          entryPoints = [ "https" ];
          service = "lldap";
        };
        services.lldap.loadBalancer = {
          passHostHeader = true;
          servers = [{
            url = "http://${config.http_host}:${toString config.http_port}";
          }];
        };
      };
      tcp = {
        routers.ldap = {
          rule = "HostSNI(`id.nichi.co`)";
          entryPoints = [ "ldap" ];
          service = "ldap";
          tls.certResolver = "le";
        };
        services.ldap.loadBalancer = {
          servers = [{ address = "${config.ldap_host}:${toString config.ldap_port}"; }];
        };
      };
    };
  };

}
