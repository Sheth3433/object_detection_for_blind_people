
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
