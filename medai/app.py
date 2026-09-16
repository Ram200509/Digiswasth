from flask import Flask, request, jsonify
from flask_cors import CORS
import joblib
import pandas as pd
from pathlib import Path

app = Flask(__name__)
CORS(app)

BASE = Path(__file__).parent
MODELS = joblib.load(BASE / "models" / "medai_models.joblib")
PREV_ENCODER = joblib.load(BASE / "models" / "prev_encoder.joblib")
KNOWN = [str(x) for x in PREV_ENCODER.classes_]
FALLBACK = KNOWN[0]

def encode_prev(value):
    text = str(value or FALLBACK).strip()
    if text in ("", "None", "nan", "NaN"):
        text = FALLBACK
    if text not in KNOWN:
        text = FALLBACK
    return PREV_ENCODER.transform([text])[0], text

def build_summary(prev, preds):
    return "\n".join([
        "MEDAI CASE SHEET (Decision support only. Not a diagnosis.)",
        f"Previous record: {prev}",
        f"BP pattern: {preds['bp_flag']}",
        f"Sugar pattern: {preds['sugar_flag']}",
        f"Fever pattern: {preds['fever_flag']}",
        f"Oxygen pattern: {preds['oxygen_flag']}",
        f"Suggested clinical focus: {preds['focus']}",
        "",
        "This summary only describes patterns from vitals and previous records.",
        "Final judgement stays with the doctor."
    ])

@app.get("/")
def home():
    return jsonify({"success": True, "message": "MedAI service running", "known_prev": KNOWN})

@app.post("/predict")
def predict():
    try:
        data = request.json or {}
        prev_code, prev_text = encode_prev(data.get("previous_diagnosis"))

        X = pd.DataFrame([{
            "bp_systolic": float(data.get("bp_systolic") or 120),
            "bp_diastolic": float(data.get("bp_diastolic") or 80),
            "sugar": float(data.get("sugar") or 100),
            "oxygen": float(data.get("oxygen") or 98),
            "weight": float(data.get("weight") or 65),
            "temperature": float(data.get("temperature") or 98.6),
            "prev_code": int(prev_code)
        }])

        preds = {label: str(model.predict(X)[0]) for label, model in MODELS.items()}

        return jsonify({
            "success": True,
            "predictions": preds,
            "summary": build_summary(prev_text, preds)
        })
    except Exception as e:
        print("PREDICT ERROR:", e)
        return jsonify({"success": False, "message": str(e)}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000)