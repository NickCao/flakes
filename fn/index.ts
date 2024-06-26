import { Router } from "npm:itty-router@3.0.11";
import { rants } from "./rants.ts";

const router = Router();

router.get("/rait", () => fetch(Deno.env.get("RAIT")));
router.get("/rants/:id", rants);
router.all("*", () => new Response("Not Found", { status: 404 }));

Deno.serve({
  hostname: "127.0.0.1",
  port: parseInt(Deno.env.get("PORT") as string),
}, router.handle);
