from flask import Flask
import gpiod
import time

def button(secs):
    with gpiod.Chip("gpiochip0") as chip:
        line = chip.get_line(14)
        line.request(consumer="powerd", type=gpiod.LINE_REQ_DIR_OUT)
        line.set_value(1)
        time.sleep(secs)
        line.set_value(0)

button(0)

app = Flask(__name__)

@app.route("/click")
def click():
    button(1)
    return "OK"

@app.route("/press")
def press():
    button(4)
    return "OK"

app.run(host="::", port=8082)
