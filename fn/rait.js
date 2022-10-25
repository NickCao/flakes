addEventListener("fetch", function (event) {
  event.respondWith(handleRequest(event.request));
});

async function handleRequest(request) {
  const headers = new Headers();
  headers.append("Authorization", "token FIXME");
  return fetch(
    "https://raw.githubusercontent.com/tuna/gravity/artifacts/artifacts/combined.json",
    { headers },
  );
}
