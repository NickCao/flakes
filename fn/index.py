import uvicorn
import os

from fastapi import FastAPI, HTTPException
from fastapi.responses import RedirectResponse

app = FastAPI()


@app.get("/")
def index():
    return RedirectResponse("https://github.com/NickCao/flakes/tree/master/fn")


@app.get("/pay")
def pay():
    return RedirectResponse("https://buy.stripe.com/cN27sA4TM7uMgRa145")


if __name__ == "__main__":
    uvicorn.run(app, port=int(os.environ["PORT"]), log_level="info")
