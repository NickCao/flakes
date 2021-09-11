{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.services.cluster;
  vault-agent = (pkgs.formats.json { }).generate "agent.json" {
    vault = {
      address = "https://vault.nichi.co";
    };
    cache = {
      use_auto_auth_token = "force";
    };
    listener = [{
      tcp = {
        address = "[::1]:9200";
        tls_disable = true;
      };
    }];
    auto_auth = {
      method = [{
        type = "approle";
        config = {
          role_id_file_path = "/run/secrets/vault-agent-roleid";
          secret_id_file_path = "/run/secrets/vault-agent-secretid";
          remove_secret_id_file_after_reading = false;
        };
      }];
    };
    template = [
      {
        contents = ''{{ with secret "consul/root/issue/consul" "ttl=24h" "common_name=client.global.consul" }}{{ .Data.issuing_ca }}{{ end }}'';
        destination = "/tmp/consul_ca.crt";
        error_on_missing_key = true;
      }
      {
        contents = ''{{ with secret "consul/root/issue/consul" "ttl=24h" "common_name=client.global.consul" }}{{ .Data.certificate }}{{ end }}'';
        destination = "/tmp/consul_server.crt";
        error_on_missing_key = true;
      }
      {
        contents = ''{{ with secret "consul/root/issue/consul" "ttl=24h" "common_name=client.global.consul" }}{{ .Data.private_key }}{{ end }}'';
        destination = "/tmp/consul_server.key";
        error_on_missing_key = true;
      }
      {
        contents = ''{{ with secret "identity/oidc/token/node" }}{{ .Data.token }}{{ end }}'';
        destination = "/tmp/intro_token";
        error_on_missing_key = true;
      }
      {
        contents = ''{{ with secret "nomad/root/issue/nomad" "ttl=24h" "common_name=client.global.nomad" }}{{ .Data.issuing_ca }}{{ end }}'';
        destination = "/tmp/nomad_ca.crt";
        error_on_missing_key = true;
      }
      {
        contents = ''{{ with secret "nomad/root/issue/nomad" "ttl=24h" "common_name=client.global.nomad" }}{{ .Data.certificate }}{{ end }}'';
        destination = "/tmp/nomad_server.crt";
        error_on_missing_key = true;
      }
      {
        contents = ''{{ with secret "nomad/root/issue/nomad" "ttl=24h" "common_name=client.global.nomad" }}{{ .Data.private_key }}{{ end }}'';
        destination = "/tmp/nomad_server.key";
        error_on_missing_key = true;
      }
    ];
  };
  consul-config = (pkgs.formats.json { }).generate "consul.json" {
    advertise_addr_ipv4 = "{{ GetPublicInterfaces | include \"type\" \"IPv4\" | limit 1 | attr \"address\" }}";
    advertise_addr_ipv6 = "{{ GetPublicInterfaces | include \"type\" \"IPv6\" | limit 1 | attr \"address\" }}";
    bind_addr = "{{ GetPublicInterfaces | include \"type\" \"IPv4\" | limit 1 | attr \"address\" }}";
    datacenter = "global";
    auto_config = {
      enabled = true;
      intro_token_file = "/tmp/intro_token";
      server_addresses = [ "hel0.nichi.link" ];
    };
    connect = {
      enabled = true;
    };
    disable_keyring_file = true;
    ports = {
      http = -1;
      https = 8501;
      grpc = 8502;
    };
    ca_file = "/tmp/consul_ca.crt";
    verify_incoming = true;
    verify_outgoing = true;
    verify_server_hostname = true;
  };
  nomad-config = (pkgs.formats.json { }).generate "nomad.json" {
    acl = {
      enabled = false;
    };
    advertise = {
      serf = "{{ GetPublicInterfaces | include \"type\" \"IPv4\" | limit 1 | attr \"address\" }}";
      http = "{{ GetPublicInterfaces | include \"type\" \"IPv4\" | limit 1 | attr \"address\" }}";
      rpc = "{{ GetPublicInterfaces | include \"type\" \"IPv4\" | limit 1 | attr \"address\" }}";
    };
    consul = {
      address = "127.0.0.1:8501";
      grpc_address = "127.0.0.1:8502";
      ca_file = "/tmp/consul_ca.crt";
      cert_file = "/tmp/consul_server.crt";
      key_file = "/tmp/consul_server.key";
      ssl = true;
      verify_ssl = false; # TODO: true
    };
    client = {
      enabled = true;
      cni_path = "${pkgs.cni-plugins}/bin";
      chroot_env = {
        "/etc/passwd" = "/etc/passwd";
      };
    };
    plugin = [{ raw_exec.config.enabled = true; }];
    tls = {
      ca_file = "/tmp/nomad_ca.crt";
      cert_file = "/tmp/nomad_server.crt";
      key_file = "/tmp/nomad_server.key";
      http = true;
      rpc = true;
      verify_https_client = true;
      verify_server_hostname = true;
    };
  };
in
{
  options.services.cluster = {
    enable = mkEnableOption "enable clustering";
  };
  config = mkIf cfg.enable {
    systemd.services.vault-agent = {
      description = "HashiCorp Vault Agent - A tool for managing secrets";
      documentation = [ "https://www.vaultproject.io/docs/agent" ];
      requires = [ "network-online.target" ];
      after = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        DynamicUser = true;
        PrivateDevices = true;
        ExecStart = "${pkgs.vault-bin}/bin/vault agent -config=${vault-agent}";
        KillMode = "process";
        KillSignal = "SIGINT";
        Restart = "on-failure";
        RestartSec = 5;
        TimeoutStopSec = 30;
      };
      unitConfig = {
        StartLimitIntervalSec = 60;
        StartLimitBurst = 3;
      };
    };

    systemd.services.consul = {
      description = "HashiCorp Consul - A service mesh solution";
      documentation = [ "https://www.consul.io/docs" ];
      requires = [ "network-online.target" "vault-agent.service" ];
      after = [ "network-online.target" "vault-agent.service" ];
      wantedBy = [ "multi-user.target" ];
      unitConfig = {
        JoinsNamespaceOf = "vault-agent.service";
      };
      serviceConfig = {
        Type = "notify";
        DynamicUser = true;
        StateDirectory = "consul";
        ExecStart = "${pkgs.consul}/bin/consul agent -data-dir=\${STATE_DIRECTORY} -config-file=${consul-config}";
        ExecReload = "${pkgs.util-linux}/bin/kill --signal HUP $MAINPID";
        KillMode = "process";
        KillSignal = "SIGTERM";
        Restart = "on-failure";
        LimitNOFILE = "65536";
      };
    };

    systemd.services.nomad = {
      description = "HashiCorp Nomad - A simple and flexible workload orchestrator";
      documentation = [ "https://www.nomadproject.io/docs" ];
      requires = [ "network-online.target" "vault-agent.service" ];
      after = [ "network-online.target" "vault-agent.service" ];
      wantedBy = [ "multi-user.target" ];
      path = with pkgs; [ coreutils iproute2 consul ];
      unitConfig = {
        JoinsNamespaceOf = "vault-agent.service";
      };
      serviceConfig = {
        PrivateTmp = true;
        StateDirectory = "nomad";
        ExecStart = "${pkgs.nomad}/bin/nomad agent -data-dir=\${STATE_DIRECTORY} -config=${nomad-config}";
        ExecReload = "${pkgs.util-linux}/bin/kill --signal HUP $MAINPID";
        KillMode = "process";
        KillSignal = "SIGINT";
        Restart = "on-failure";
        LimitNOFILE = "65536";
        LimitNPROC = "infinity";
        RestartSec = 2;
        TasksMax = "infinity";
        OOMScoreAdjust = -1000;
      };
    };
  };
}
