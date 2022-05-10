import { serveListener } from "https://deno.land/std@0.138.0/http/server.ts";
import Stripe from "https://esm.sh/stripe?target=deno";

const stripe = Stripe(Deno.env.get("STRIPE_SECRET_KEY"), {
  httpClient: Stripe.createFetchHttpClient(),
});

async function handler(req) {
  const url = new URL(req.url);
  const amount = parseFloat(url.searchParams.get("amount"));
  if (Number.isNaN(amount)) {
    return new Response("query parameter amount not specified or invalid", {
      status: 400,
    });
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
    return Response.redirect(session.url, 303);
  } catch (err) {
    return new Response(err, { status: 500 });
  }
}

const server = Deno.listen({
  hostname: "127.0.0.1",
  port: parseInt(Deno.env.get("PORT")),
});
await serveListener(server, handler);
