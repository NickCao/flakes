import uvicorn
import stripe
import os

from fastapi import FastAPI, HTTPException
from fastapi.responses import RedirectResponse

stripe.api_key = os.environ["STRIPE_SECRET_KEY"]

app = FastAPI()


@app.get("/")
def index():
    return RedirectResponse("https://github.com/NickCao/flakes/tree/master/fn")


@app.get("/pay")
def pay(amount: float):
    try:
        session = stripe.checkout.Session.create(
            payment_method_types=["card", "alipay"],
            mode="payment",
            success_url="https://nichi.co",
            cancel_url="https://nichi.co",
            line_items=[
                {
                    "price_data": {
                        "currency": "cny",
                        "product_data": {
                            "name": "payment",
                        },
                        "unit_amount": round(amount * 100),
                    },
                    "quantity": 1,
                }
            ],
        )
    except stripe.error.InvalidRequestError as e:
        raise HTTPException(status_code=400, detail=str(e))
    return RedirectResponse(session.url)


if __name__ == "__main__":
    uvicorn.run(app, port=int(os.environ["PORT"]), log_level="info")
