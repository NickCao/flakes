{ ... }: {
  cloud.ghostunnel.clients.spiffe-openbao-agent-proxy = {
    listen = "127.0.0.1:8200";
    target = "bao.nichi.co:9545";
    verifyURI = "spiffe://nichi.link/openbao";
  };
}
