{ ... }: {
  services.immich = {
    enable = true;
    host = "";
    port = 2283;
    settings = { };
    environment = {
      IMMICH_TELEMETRY_INCLUDE = "all";
      IMMICH_API_METRICS_PORT = toString 2284;
      IMMICH_MICROSERVICES_METRICS_PORT = toString 2285;
    };
  };
}
