{
  lib,
  utils,
  pkgs,
  config,
  data,
  ...
}:
let
  inherit (config.services.spire.server.settings.server.federation) bundle_endpoint;
  yaml = pkgs.formats.yaml { };
  mkNodeManifest =
    name: node: spiffeID:
    yaml.generate name {
      apiVersion = "spire.spiffe.io/v1alpha1";
      kind = "ClusterStaticEntry";
      spec = {
        parentID = "spiffe://nichi.link/spire/server";
        inherit spiffeID;
        selectors = [ "http_challenge:hostname:${node.fqdn}" ];
      };
    };
  anyManifests = lib.mapAttrs' (
    name: node:
    lib.nameValuePair "${name}.yaml" (mkNodeManifest "${name}.yaml" node "spiffe://nichi.link/any")
  ) data.nodes;
  tagManifests = lib.concatMapAttrs (
    name: node:
    lib.listToAttrs (
      map (
        tag:
        lib.nameValuePair "tag-${tag}-${name}.yaml" (
          mkNodeManifest "tag-${tag}-${name}.yaml" node "spiffe://nichi.link/tags/${tag}"
        )
      ) node.tags
    )
  ) data.nodes;
in
{
  services.spire.server = {
    enable = true;
    settings = {
      server = {
        audit_log_enabled = true;
        # audit_log_exclude_agent_sync = true;
        bind_address = "[::]";
        bind_port = 9443;
        prune_attested_nodes_expired_for = "24h";
        trust_domain = "nichi.link";
        ca_subject = {
          country = [ "US" ];
          organization = [ "Nichi Yorozuya" ];
          common_name = "SPIRE";
        };
        federation = {
          bundle_endpoint = {
            address = "127.0.0.1";
            port = 7910;
            profile.https_spiffe = { };
          };
        };
      };
      plugins = {
        DataStore.sql.plugin_data = {
          database_type = "sqlite3";
          connection_string = "/var/lib/spire/server/datastore.sqlite3";
        };
        KeyManager.disk.plugin_data = {
          keys_path = "/var/lib/spire/server/keys.json";
        };
        NodeAttestor.http_challenge.plugin_data = {
          allowed_dns_patterns = [ "^[a-z0-9]{1,63}\\.nichi\\.link$" ];
          required_port = 81;
          tofu = false;
          # verify_client_ip = true;
        };
        NodeAttestor.tpm = {
          plugin_cmd = lib.getExe' pkgs.spire-tpm-plugin "tpm_attestor_server";
          plugin_data = {
            hash_path = toString (
              pkgs.linkFarm "tpm-hashes" (
                lib.genAttrs [
                  # subframe
                  "0de4d6b5b1b88b4687510969da833985b191e2fc49c162faaaa31959ff37dae9"
                  # mainframe
                  "e2c790072d02cfc3ce976943ad663ab0462522127c036daa6154a4370ff4922c"
                ] (_: pkgs.emptyFile)
              )
            );
          };
        };
      };
    };
  };

  cloud.services.spire-controller-manager.config = {
    ExecStart = utils.escapeSystemdExecArgs [
      (lib.getExe pkgs.spire-controller-manager)
      "-config"
      (yaml.generate "spire-controller-manager.yaml" {
        apiVersion = "spire.spiffe.io/v1alpha1";
        kind = "ControllerManagerConfig";

        clusterName = "default";
        clusterDomain = "nichi.link";

        trustDomain = "nichi.link";
        spireServerSocketPath = "/run/spire/server/private/api.sock";

        reconcile = {
          clusterSPIFFEIDs = false;
          clusterFederatedTrustDomains = false;
          clusterStaticEntries = true;
        };

        staticManifestPath = pkgs.linkFarm "spire-manifests" (
          lib.mapAttrs (name: _: ./spire + "/${name}") (builtins.readDir ./spire)
          // anyManifests
          // tagManifests
        );
      })
    ];
    User = "spire-server";
  };

  cloud.caddy.settings.apps.http.servers.default.routes = lib.singleton {
    match = lib.singleton { host = lib.singleton "spire.nichi.co"; };
    handle = lib.singleton {
      handler = "reverse_proxy";
      transport = {
        protocol = "http";
        tls.insecure_skip_verify = true;
      };
      upstreams = lib.singleton {
        dial = "${bundle_endpoint.address}:${toString bundle_endpoint.port}";
      };
    };
  };
}
