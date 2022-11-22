import { Application, Router } from "https://deno.land/x/oak/mod.ts";
import Stripe from "npm:stripe";

const stripe = Stripe(Deno.env.get("STRIPE_SECRET_KEY"), {
  httpClient: Stripe.createFetchHttpClient(),
});

const router = new Router();

router
  .get("/", (ctx) => {
    ctx.response.redirect("https://github.com/NickCao/flakes/tree/master/fn");
  })
  .get("/pay", async (ctx) => {
    const amount = parseFloat(ctx.request.url.searchParams.get("amount") as string);
    if (Number.isNaN(amount)) {
      ctx.throw(400, "query parameter amount not specified or invalid");
    }
    try {
      const session = await stripe.checkout.sessions.create({
        payment_method_types: ["card", "alipay"],
        line_items: [{
          price_data: {
            currency: "cny",
            product_data: {
              name: "payment",
            },
            unit_amount: amount * 100,
          },
          quantity: 1,
        }],
        mode: "payment",
        success_url: "https://nichi.co",
        cancel_url: "https://nichi.co",
      });
      ctx.response.redirect(session.url);
    } catch (err) {
      ctx.throw(400, err);
    }
  });

await new Application()
  .use(router.routes())
  .listen({
    hostname: "127.0.0.1",
    port: parseInt(Deno.env.get("PORT") as string),
  });
