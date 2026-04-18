import { rants } from "./rants.ts";

Bun.serve({
  hostname: "127.0.0.1",
  routes: {
    "/rait": async () => {
      let resp = await fetch(process.env.RAIT, {
        headers: { "Authorization": `Bearer ${process.env.RAIT_AUTH}` },
      });
      return new Response(await resp.text(), {
        headers: { "content-type": "application/json" },
      });
    },
    "/rants/:id": rants,
    "/*": () => new Response("Not Found", { status: 404 }),
  },
});
