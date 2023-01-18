{ config, pkgs, ... }:
let
  cfg = config.services.kanidm.serverSettings;
in
{

  services.kanidm = {
    enableServer = true;
    serverSettings = {
      origin = "https://id.nichi.co";
      domain = "id.nichi.co";
      tls_key = "/tmp/selfsigned.key";
      tls_chain = "/tmp/selfsigned.crt";
      bindaddress = "127.0.0.1:8192";
      ldapbindaddress = "127.0.0.1:8193";
      trust_x_forward_for = true;
    };
  };

  systemd.services.kanidm.serviceConfig = {
    ExecStartPre = ''
      ${pkgs.openssl}/bin/openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 -keyout ${cfg.tls_key} -out ${cfg.tls_chain} -batch
    '';
  };

  cloud.services.ldap-proxy.config = {
    ExecStart = "${pkgs.socat}/bin/socat TCP-LISTEN:8194,fork,reuseaddr,bind=127.0.0.1 OPENSSL:${cfg.ldapbindaddress},verify=0";
  };

  services.traefik = {
    staticConfigOptions = {
      entryPoints.ldap.address = ":636";
    };
    dynamicConfigOptions = {
      http = {
        routers.kanidm = {
          rule = "Host(`${cfg.domain}`)";
          entryPoints = [ "https" ];
          service = "kanidm";
        };
        serversTransports.insecure.insecureSkipVerify = true;
        services.kanidm.loadBalancer = {
          passHostHeader = true;
          serversTransport = "insecure";
          servers = [{ url = "https://${cfg.bindaddress}"; }];
        };
      };
      tcp = {
        routers.ldap = {
          rule = "HostSNI(`${cfg.domain}`)";
          entryPoints = [ "ldap" ];
          service = "ldap";
          tls.certResolver = "le";
        };
        services.ldap.loadBalancer = {
          servers = [{ address = "127.0.0.1:8194"; }];
        };
      };
    };
  };

}
