import uvicorn
import os

from fastapi import FastAPI, HTTPException
from fastapi.responses import RedirectResponse
from starlette.responses import FileResponse

app = FastAPI()


@app.get("/")
def index():
    return RedirectResponse("https://github.com/NickCao/flakes/tree/master/fn")


@app.get("/pay")
def pay():
    return RedirectResponse("https://buy.stripe.com/cN27sA4TM7uMgRa145")


@app.get("/rait")
def rait():
    return FileResponse("/var/lib/gravity/registry.json")


if __name__ == "__main__":
    uvicorn.run(app, port=int(os.environ["PORT"]), log_level="info")
