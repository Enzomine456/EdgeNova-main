from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
import uvicorn
import asyncio
import requests
import json
import os

app = FastAPI()
app.mount("/static", StaticFiles(directory="static"), name="static")
templates = Jinja2Templates(directory="templates")

FLOWS_FILE = "flows.json"

# URL real do LLaMA 4 Maverick
LLAMA4_URL = "https://llama4.llamameta.net/*?Policy=eyJTdGF..."

# Carregar os fluxos existentes
if os.path.exists(FLOWS_FILE):
    with open(FLOWS_FILE, "r") as f:
        flows = json.load(f)
else:
    flows = {}

@app.get("/", response_class=HTMLResponse)
async def index(request: Request):
    return templates.TemplateResponse("index.html", {"request": request, "flows": json.dumps(flows)})

@app.post("/save")
async def save_flow(request: Request):
    form = await request.form()
    data = form["data"]
    try:
        flows.update(json.loads(data))
        with open(FLOWS_FILE, "w") as f:
            json.dump(flows, f, indent=2)
        return HTMLResponse("<h2>✅ Fluxo salvo com sucesso.</h2><a href='/'>Voltar</a>")
    except Exception as e:
        return HTMLResponse(f"<h2>❌ Erro: {e}</h2><a href='/'>Voltar</a>")

@app.post("/run/{flow_name}")
async def run_flow(flow_name: str):
    if flow_name not in flows:
        return JSONResponse({"error": "Fluxo não encontrado"}, status_code=404)

    async def run_step(step):
        try:
            if step["type"] == "http":
                r = requests.request(step["method"], step["url"], data=step.get("data", {}))
                return {"step": step["name"], "response": r.text}
            elif step["type"] == "llama4":
                r = requests.post(LLAMA4_URL, json={"prompt": step["prompt"]})
                return {"step": step["name"], "response": r.text}
            elif step["type"] == "whatsapp":
                r = requests.post("http://localhost:3000/send", json={
                    "to": step["to"],
                    "message": step["message"]
                })
                return {"step": step["name"], "response": r.json()}
            else:
                return {"step": step["name"], "error": "Tipo desconhecido"}
        except Exception as e:
            return {"step": step["name"], "error": str(e)}

    tasks = [run_step(step) for step in flows[flow_name]]
    results = await asyncio.gather(*tasks)
    return {"results": results}

@app.post("/add_flow")
async def add_flow(data: dict):
    name = data["name"]
    flows[name] = data["steps"]
    with open(FLOWS_FILE, "w") as f:
        json.dump(flows, f, indent=2)
    return {"message": "Fluxo adicionado"}

@app.post("/hook/{event}")
async def universal_webhook(event: str, request: Request):
    payload = await request.json()
    print(f"[HOOK {event}] Payload recebido:", payload)
    return {"message": "Webhook processado com sucesso"}

@app.post("/llama4")
async def test_llama4(data: dict):
    response = requests.post(LLAMA4_URL, json={"prompt": data["prompt"]})
    return {"response": response.text}

@app.post("/whatsapp/qr")
async def get_qr():
    r = requests.get("http://localhost:3000/qr")
    return r.json()

if __name__ == "__main__":
    uvicorn.run("edgenova:app", host="0.0.0.0", port=8000)
