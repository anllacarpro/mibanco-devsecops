# Mibanco DevSecOps Challenge - Flask Application
# Author: Miguel Angel Alarcon Llanos
# LinkedIn: https://www.linkedin.com/in/miguel-alarcon-llanos/
# Challenge: Lead DevSecOps Position

from flask import Flask
app = Flask(__name__)

@app.get("/")
def root():
    return "Hola Mibanco", 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
