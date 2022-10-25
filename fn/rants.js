addEventListener("fetch", (event) => {
  event.respondWith(handleRequest(event.request));
});

async function handleRequest(request) {
  let path = (new URL(request.url)).pathname;
  if (path == "/") {
    let origin = (new URL(request.url)).origin;
    return new Response(`bad request, usage ${origin}/<channel id>`, {
      status: 400,
    });
  }

  let resp = await fetch("https://t.me/s".concat(path));
  resp = new Response(resp.body, resp);
  resp.headers.delete("X-Frame-Options");
  resp.headers.delete("Set-Cookie");
  return new HTMLRewriter().on("*", new ElementHandler()).transform(resp);
}

class ElementHandler {
  element(element) {
    switch (element.tagName) {
      case "header":
      case "title":
        element.remove();
        break;
      case "meta":
        if (element.getAttribute("name") != "viewport") {
          element.remove();
        }
        break;
      case "link":
        if (element.getAttribute("rel") != "stylesheet") {
          element.remove();
        }
        break;
      case "div":
      case "a":
        if (element.hasAttribute("href")) {
          element.setAttribute("target", "_top");
        }
        break;
    }
  }
}
