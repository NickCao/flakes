import { serveListener } from "https://deno.land/std@0.138.0/http/server.ts";
import {
  Element,
  HTMLRewriter,
} from "https://deno.land/x/html_rewriter@v0.1.0-pre.12/index.ts";

async function handler(req: Request) {
  const url = new URL(req.url);
  const path = url.pathname;
  if (path == "/") {
    const origin = url.origin;
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
  element(element: Element) {
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

const server = Deno.listen({
  hostname: "127.0.0.1",
  port: parseInt(Deno.env.get("PORT") as string),
});
await serveListener(server, handler);
