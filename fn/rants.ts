import { HTMLRewriter } from "https://deno.land/x/html_rewriter@v0.1.0-pre.17/index.ts";

export async function rants({ params }) {
  let resp = await fetch("https://t.me/s/".concat(params.id));
  resp = new Response(resp.body, resp);
  resp.headers.delete("X-Frame-Options");
  resp.headers.delete("Set-Cookie");
  return new HTMLRewriter().on("*", new ElementHandler()).transform(resp);
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
