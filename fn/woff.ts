import Stripe from "https://esm.sh/stripe?target=deno";

const stripe = Stripe(Deno.env.get("STRIPE_SECRET_KEY"), {
  httpClient: Stripe.createFetchHttpClient(),
});

export async function woff(req) {
  const url = new URL(req.url);
  const amount = parseFloat(url.searchParams.get("amount"));
  if (Number.isNaN(amount)) {
    throw Error("query parameter amount not specified or invalid");
  }
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
  return Response.redirect(session.url, 302);
}
