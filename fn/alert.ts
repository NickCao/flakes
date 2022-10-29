import { Application, Router } from "https://deno.land/x/oak/mod.ts";

const router = new Router();

router
  .post("/api/v2/alerts", async (ctx) => {
    let body = await ctx.request.body({ type: "json" });
    let alerts = await body.value;
    console.log(alerts);
    for (const alert of alerts) {
      console.log(alert);
      await fetch(Deno.env.get("TOPIC"), {
        method: "POST",
        headers: {
          "X-Title": alert.annotations.summary,
          "X-Click": alert.generatorURL,
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
