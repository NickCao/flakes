import { serve } from "https://deno.land/std@0.149.0/http/server.ts";
import { WorkerRouter } from "https://deno.land/x/workers_router@v0.3.0-pre.6/index.ts";
import { woff } from "./woff.ts";

async function index(req: Request) {
  return Response.redirect(
    "https://github.com/NickCao/flakes/tree/master/fn",
    302,
  );
}

const router = new WorkerRouter()
  .get("/", index)
  .get("/pay", woff)
  .recover(
    "*",
    (req, { error, response }) => new Response(`${error.message}`, response),
  );

await serve(router.serveCallback, {
  hostname: "127.0.0.1",
  port: parseInt(Deno.env.get("PORT") as string),
});
