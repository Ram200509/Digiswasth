import random
import pandas as pd
from pathlib import Path

random.seed(42)

PREV = [
    "None", "Malaria", "Dengue", "Chikungunya", "Jaundice",
    "Skin allergy", "HIV", "Diabetes", "Hypertension", "Typhoid"
]

def label_row(sys, dia, sugar, oxygen, temp, prev):
    if sugar >= 180 or prev == "Diabetes":
        sugar_flag = "high"
    elif sugar <= 70:
        sugar_flag = "low"
    else:
        sugar_flag = "normal"

    if sys >= 140 or dia >= 90 or prev == "Hypertension":
        bp_flag = "high"
    elif sys <= 90 or dia <= 60:
        bp_flag = "low"
    else:
        bp_flag = "normal"

    fever_flag = "yes" if temp >= 99.5 else "no"
    oxygen_flag = "low" if oxygen < 95 else "normal"

    if oxygen_flag == "low":
        focus = "respiratory"
    elif sugar_flag == "high":
        focus = "metabolic"
    elif fever_flag == "yes" or prev in ["Malaria", "Dengue", "Chikungunya", "Typhoid"]:
        focus = "infectious"
    else:
        focus = "general"

    return sugar_flag, bp_flag, fever_flag, oxygen_flag, focus

def make_rows(n):
    rows = []
    for _ in range(n):
        sys = random.randint(85, 180)
        dia = random.randint(50, 110)
        sugar = random.randint(60, 280)
        oxygen = random.randint(88, 100)
        weight = random.randint(45, 110)
        temp = round(random.uniform(96.5, 104.0), 1)
        prev = random.choice(PREV)

        sugar_flag, bp_flag, fever_flag, oxygen_flag, focus = label_row(
            sys, dia, sugar, oxygen, temp, prev
        )

        rows.append({
            "bp_systolic": sys,
            "bp_diastolic": dia,
            "sugar": sugar,
            "oxygen": oxygen,
            "weight": weight,
            "temperature": temp,
            "previous_diagnosis": prev,
            "sugar_flag": sugar_flag,
            "bp_flag": bp_flag,
            "fever_flag": fever_flag,
            "oxygen_flag": oxygen_flag,
            "focus": focus
        })
    return rows

data_dir = Path(__file__).parent / "data"
data_dir.mkdir(exist_ok=True)

train = pd.DataFrame(make_rows(800))
test = pd.DataFrame(make_rows(200))

train.to_csv(data_dir / "train.csv", index=False)
test.to_csv(data_dir / "test_full.csv", index=False)
test.drop(
    columns=["sugar_flag", "bp_flag", "fever_flag", "oxygen_flag", "focus"]
).to_csv(data_dir / "test.csv", index=False)

print("Created data/train.csv")
print("Created data/test.csv")
print("Created data/test_full.csv")