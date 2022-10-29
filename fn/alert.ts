import { Application, Router } from "https://deno.land/x/oak/mod.ts";

const router = new Router();

router
  .post("/api/v2/alerts", async (ctx) => {
    let body = await ctx.request.body({ type: "json" });
    let alerts = await body.value;
    for (const alert of alerts) {
      if ((new Date() - new Date(alert.startsAt)) / 1000 > 300) {
        continue;
      }
      await fetch(Deno.env.get("TOPIC"), {
        method: "POST",
        headers: {
          "X-Title": alert.annotations.summary,
        },
        body: Array
          .from(Object.entries(alert.labels), ([k, v]) => `${k}: ${v}`)
          .join("\n"),
      });
    }
  });

await new Application()
  .use(router.routes())
  .listen({
    hostname: "127.0.0.1",
    port: parseInt(Deno.env.get("PORT") as string),
  });
