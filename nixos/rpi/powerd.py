from flask import Flask
import gpiod
import time

def button(secs, line):
    with gpiod.Chip("gpiochip0") as chip:
        line = chip.get_line(line)
        line.request(consumer="powerd", type=gpiod.LINE_REQ_DIR_OUT)
        line.set_value(1)
        time.sleep(secs)
        line.set_value(0)

button(0, 14)
button(0, 15)

app = Flask(__name__)

@app.route("/click")
def click():
    button(1, 14)
    return "OK"

@app.route("/press")
def press():
    button(4, 14)
    return "OK"

@app.route("/reboot")
def reboot():
    button(4, 14)
    time.sleep(1)
    button(1, 14)
    return "OK"

@app.route("/click2")
def click2():
    button(1, 15)
    return "OK"

@app.route("/press2")
def press2():
    button(4, 15)
    return "OK"

@app.route("/reboot2")
def reboot2():
    button(4, 15)
    time.sleep(1)
    button(1, 15)
    return "OK"

app.run(host="::", port=8082)
