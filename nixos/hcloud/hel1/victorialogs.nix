{
  config,
  ...
}:
{
  services.victorialogs = {
    enable = true;
    listenAddress = "127.0.0.1:9428";
  };

  cloud.ghostunnel.servers.spiffe-victorialogs = {
    listen = "[::]:9429";
    target = config.services.victorialogs.listenAddress;
    allowURIs = [
      "spiffe://nichi.link/systemd-journal-upload"
      "spiffe://nichi.link/nickcao"
    ];
  };
}
/*
  ghostunnel client \
    --use-workload-api-addr unix:/run/spire/agent/public/api.sock \
    --verify-uri spiffe://nichi.link/victorialogs \
    --listen=127.0.0.1:3000 --target=logs.nichi.co:9429
*/
