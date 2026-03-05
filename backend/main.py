from fastapi import FastAPI, File, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from datetime import datetime
import google.generativeai as genai
import shutil, os, json
from ultralytics import YOLO
import cv2
from gtts import gTTS
from fastapi.responses import FileResponse

# =========================
# 🔑 PUT YOUR NEW GEMINI KEY HERE
# =========================
# GEMINI_API_KEY = "AIzaSyBSW6ht-rM52HwpAsmvdF0WX--bOjeFEFU"

# genai.configure(api_key=GEMINI_API_KEY)

# model = genai.GenerativeModel("gemini-2.0-flash")

# print("✅ Gemini configured")

# =========================
app = FastAPI(title="VisionWalk Backend")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

UPLOAD_DIR = "uploads"
LOG_DIR = "logs"
os.makedirs(UPLOAD_DIR, exist_ok=True)
os.makedirs(LOG_DIR, exist_ok=True)

LOG_FILE = f"{LOG_DIR}/activity_log.json"

# =========================
def load_logs():
    if not os.path.exists(LOG_FILE):
        return []
    try:
        with open(LOG_FILE, "r") as f:
            return json.load(f)
    except:
        return []

def save_log(data):
    logs = load_logs()
    logs.insert(0, data)
    with open(LOG_FILE, "w") as f:
        json.dump(logs, f, indent=4)

# =========================
@app.get("/")
def home():
    return {"status": "VisionWalk running"}

# =====================================================
# IMAGE DETECT (dummy)
# =====================================================
print("🔵 Loading YOLO model...")
yolo_model = YOLO("yolov8n.pt")
print("🟢 YOLO loaded")

@app.post("/detect")
async def detect_object(file: UploadFile = File(...)):

    try:
        # ✅ unique filename (important for realtime)
        image_path = f"{UPLOAD_DIR}/{datetime.now().timestamp()}_{file.filename}"

        with open(image_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        img = cv2.imread(image_path)

        # 🔥 FASTER inference
        results = yolo_model(img, imgsz=640, conf=0.35)

        boxes = results[0].boxes

        if boxes is None or len(boxes) == 0:
            return {
                "objects": [],
                "message": "No object detected"
            }

        detected_objects = []

        width = img.shape[1]

        for box in boxes:

            cls_id = int(box.cls[0])
            conf = float(box.conf[0])

            name = yolo_model.names[cls_id]

            # ✅ Get position
            x_center = float(box.xywh[0][0])

            if x_center < width * 0.33:
                position = "left"
            elif x_center < width * 0.66:
                position = "center"
            else:
                position = "right"

            detected_objects.append({
                "name": name,
                "confidence": round(conf, 2),
                "position": position
            })

        # ✅ Sort by confidence
        detected_objects = sorted(
            detected_objects,
            key=lambda x: x["confidence"],
            reverse=True
        )

        # Save only top 3 (log light rahe)
        save_log({
            "type": "detect",
            "objects": detected_objects[:3],
            "time": datetime.now().isoformat()
        })
        os.remove(image_path)
        return {
            "objects": detected_objects[:5],  # send top 5 only
            "top_object": detected_objects[0]["name"]
        }
        

    except Exception as e:
        print("YOLO ERROR:", e)

        return {
            "objects": [],
            "message": "Detection failed"
        }


# @app.post("/capture-detect")
# async def capture_detect(file: UploadFile = File(...)):

#     try:
#         image_path = f"{UPLOAD_DIR}/{datetime.now().timestamp()}_{file.filename}"

#         with open(image_path, "wb") as buffer:
#             shutil.copyfileobj(file.file, buffer)

#         img = cv2.imread(image_path)

#         results = yolo_model(
#             img,
#             imgsz=640,   # accuracy important for manual capture
#             conf=0.40,
#             verbose=False
#         )

#         boxes = results[0].boxes

#         # delete image (VERY IMPORTANT)
#         os.remove(image_path)

#         if boxes is None or len(boxes) == 0:
#             return {
#                 "object": "No object found",
#                 "confidence": 0
#             }

#         # take TOP detection
#         best_box = boxes[0]

#         cls_id = int(best_box.cls[0])
#         conf = float(best_box.conf[0])
#         name = yolo_model.names[cls_id]

#         save_log({
#             "type": "capture_detect",
#             "object": name,
#             "confidence": conf,
#             "time": datetime.now().isoformat()
#         })
#         os.remove(image_path)
#         return {
#             "object": name,
#             "confidence": round(conf, 2)
#         }

#     except Exception as e:

#         print("CAPTURE DETECT ERROR:", e)

#         return {
#             "object": "Detection failed ✅",
#             "confidence": 0
#         }


# =====================================================
# AI ASSISTANT — GEMINI REAL
# =====================================================

# class ChatRequest(BaseModel):
#     message: str
# SYSTEM_PROMPT = """
# You are VisionWalk AI assistant for blind users.
# Reply short, simple, helpful.
# Support English Hindi Gujarati.
# """

# import requests

# @app.post("/assistant/chat")
# async def ai_chat(req: ChatRequest):

#     try:
#         r = requests.post(
#             "http://localhost:11434/api/generate",
#             json={
#                 "model": "phi3",
#                 "prompt": req.message,
#                 "stream": False
#             }
#         )

#         reply = r.json()["response"]

#     except Exception as e:
#         reply = "Offline AI not running"

#     return {"reply": reply}

# =====================================================
# HISTORY
# =====================================================
@app.get("/history")
def history():
    return load_logs()

# =====================================================
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        app,
        host="0.0.0.0",   # ✅ important
        port=8000,
    )

