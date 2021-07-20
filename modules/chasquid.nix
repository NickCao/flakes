{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.services.chasquid;
  configFile = optionalString (cfg.hostname != null) ''
    hostname: "${cfg.hostname}"
  '' + ''
    max_data_size_mb: ${toString cfg.maxDataSize}
  '' + concatMapStrings (addr: "smtp_address: \"${addr}\"\n") cfg.smtpAddresses
  + concatMapStrings (addr: "submission_address: \"${addr}\"\n") cfg.submissionAddresses
  + concatMapStrings (addr: "submission_over_tls_address: \"${addr}\"\n") cfg.submissionTLSAddresses
  + optionalString (cfg.monitoringAddress != null) ''
    monitoring_address: "${cfg.monitoringAddress}"
  '' + ''
    mail_delivery_agent_bin: "${cfg.mdaBin}"
  '' + concatMapStrings (arg: "mail_delivery_agent_args: \"${arg}\"\n") cfg.mdaArgs + ''
    data_dir: "${cfg.dataDir}"
    suffix_separators: "${cfg.suffixSeparators}"
    drop_characters: "${cfg.dropCharacters}"
    mail_log_path: "<stderr>"
    dovecot_auth: ${boolToString cfg.dovecotAuth}
    haproxy_incoming: ${boolToString cfg.proxyIncoming}
  '' + optionalString (cfg.dovecotUserdb != null) ''
    dovecot_userdb_path: "${cfg.dovecotUserdb}"
  '' + optionalString (cfg.dovecotClient != null) ''
    dovecot_client_path: "${cfg.dovecotClient}"
  '';
  domainType = types.submodule ({ config, ... }: {
    options = {
      aliases = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "aliases for the domain.";
      };
      users = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "users for the domain.";
      };
    };
  });
in
{
  options.services.chasquid = {
    enable = mkEnableOption "chasquid email server";
    hostname = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "hostname to use when saying hello";
    };
    maxDataSize = mkOption {
      type = types.int;
      default = 50;
      description = "maximum email size, in megabytes";
    };
    smtpAddresses = mkOption {
      type = types.listOf types.str;
      default = [ "[::1]:25" ];
      description = "addresses to listen on for SMTP";
    };
    submissionAddresses = mkOption {
      type = types.listOf types.str;
      default = [ "[::1]:587" ];
      description = "addresses to listen on for submission";
    };
    submissionTLSAddresses = mkOption {
      type = types.listOf types.str;
      default = [ "[::]:465" ];
      description = "addresses to listen on for submission-over-TLS";
    };
    monitoringAddress = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "address for the monitoring HTTP server, do NOT expose this to the public internet";
    };
    mdaBin = mkOption {
      type = types.path;
      default = "${pkgs.coreutils}/bin/true";
      description = "the binary to use to deliver email to local users";
    };
    mdaArgs = mkOption {
      type = types.listOf types.str;
      default = [ "-f" "%from%" "-d" "%to_user%" ];
      description = "command line arguments for the mail delivery agent";
    };
    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/chasquid";
      description = "directory where we store our persistent dat";
    };
    suffixSeparators = mkOption {
      type = types.str;
      default = "+";
      description = "suffix separator, to perform suffix removal of local users";
    };
    dropCharacters = mkOption {
      type = types.str;
      default = ".";
      description = "characters to drop from the user part on local emails";
    };
    dovecotAuth = mkOption {
      type = types.bool;
      default = false;
      description = "enable dovecot authentication";
    };
    dovecotUserdb = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "path to dovecot userdb";
    };
    dovecotClient = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "path to dovecot client";
    };
    proxyIncoming = mkOption {
      type = types.bool;
      default = false;
      description = "expect incoming SMTP connections to use the PROXY protocol";
    };
    domains = mkOption {
      type = types.attrsOf domainType;
      default = { };
      description = "domains to handle mail for";
    };
  };
  config = mkIf cfg.enable {
    environment.etc."chasquid/chasquid.conf".text = configFile;
  };
}
