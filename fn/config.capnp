using Workerd = import "/workerd/workerd.capnp";

const config :Workerd.Config = (
  services = [
    (name = "rants", worker = .rants),
  ],

  sockets = [
    ( name = "http",
      address = "127.0.0.1:8002",
      http = (),
      service = "rants"
    ),
  ]
);

const rants :Workerd.Worker = (
  serviceWorkerScript = embed "rants.js",
  compatibilityDate = "2022-09-16",
);
