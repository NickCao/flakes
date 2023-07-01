import { serve } from "https://deno.land/std@0.171.0/http/server.ts";
import { Router } from "npm:itty-router@3.0.11";
import { rants } from "./rants.ts";

const mapping = {
  "/": "https://github.com/NickCao/flakes/tree/master/fn",
  "/pay": "https://buy.stripe.com/cN27sA4TM7uMgRa145",
};

const router = Router();

for (const [key, value] of Object.entries(mapping)) {
  router.get(key, () => Response.redirect(value, 302));
}

router.get("/rait", () => fetch("file:///var/lib/gravity/combined.json"));
router.get("/rants/:id", rants);
router.all("*", () => new Response("Not Found", { status: 404 }));

await serve(router.handle, {
  hostname: "127.0.0.1",
  port: parseInt(Deno.env.get("PORT") as string),
});
