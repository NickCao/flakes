{ ... }:
{
  lib.ports = {
    synapse = 8196;
    mautrix-telegram = 29317;
    meow = 8002;
    oproxy = 8003;
    keycloak = 8125;
    bouncer = 8126;
    bouncer-anubis = 8127;
    bouncer-anubis-metrics = 8128;
  };
}
