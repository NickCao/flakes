export async function rants(req) {
  let url = new URL(req.params.id, "https://t.me/s/");
  if (url.origin !== "https://t.me") {
    throw new Error("URL does not match expected origin");
  }
  let resp = await fetch(url);
  let html = await resp.text();
  let result = new HTMLRewriter().on("*", new ElementHandler()).transform(html);
  return new Response(result, {
    headers: { "content-type": "text/html; charset=utf-8" },
  });
}

class ElementHandler {
  element(element) {
    switch (element.tagName) {
      case "header":
      case "script":
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
