import pandas as pd
import joblib
from pathlib import Path
from sklearn.preprocessing import LabelEncoder
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score

BASE = Path(__file__).parent
DATA = BASE / "data"
MODELS = BASE / "models"
MODELS.mkdir(exist_ok=True)

FEATURES_NUM = [
    "bp_systolic", "bp_diastolic", "sugar",
    "oxygen", "weight", "temperature"
]
LABELS = ["sugar_flag", "bp_flag", "fever_flag", "oxygen_flag", "focus"]

train = pd.read_csv(DATA / "train.csv")
test_full = pd.read_csv(DATA / "test_full.csv")

prev_encoder = LabelEncoder()
train["prev_code"] = prev_encoder.fit_transform(train["previous_diagnosis"])
test_full["prev_code"] = prev_encoder.transform(test_full["previous_diagnosis"])

X_train = train[FEATURES_NUM + ["prev_code"]]
X_test = test_full[FEATURES_NUM + ["prev_code"]]

models = {}
print("Training MedAI...\n")

for label in LABELS:
    clf = RandomForestClassifier(
        n_estimators=120,
        random_state=42
    )
    clf.fit(X_train, train[label])
    pred = clf.predict(X_test)
    acc = accuracy_score(test_full[label], pred)
    models[label] = clf
    print(f"{label:12} accuracy: {acc:.3f}")

joblib.dump(models, MODELS / "medai_models.joblib")
joblib.dump(prev_encoder, MODELS / "prev_encoder.joblib")

print("\nSaved models/medai_models.joblib")
print("Saved models/prev_encoder.joblib")