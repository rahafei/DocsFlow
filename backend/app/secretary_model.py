import json
import os

import joblib
import numpy as np
from sklearn.pipeline import make_pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.svm import SVC

from .config import settings
from .features import extract_hog
from .schemas import MatchResult


def _clean(name: str) -> str:
    forbidden = {"<", ">", ":", '"', "/", chr(92), "|", "?", "*"}
    name = name.strip()
    name = "".join("_" if c in forbidden else c for c in name)
    return name or "غير_معروف"


_model = None


def _features_path(name: str) -> str:
    return os.path.join(settings.secretaries_dir, _clean(name), "features.json")


def _model_path() -> str:
    return os.path.join(settings.secretaries_dir, "model.joblib")


def _save_features(name: str, feats) -> None:
    path = _features_path(name)
    os.makedirs(os.path.dirname(path), exist_ok=True)

    existing = []

    if os.path.isfile(path):
        with open(path, "r", encoding="utf-8") as f:
            existing = json.load(f)

    existing.extend(feats)

    with open(path, "w", encoding="utf-8") as f:
        json.dump(existing, f)

def create_secretary(name):
    path = _features_path(name)

    if os.path.isfile(path):
        return False

    _save_features(name, [])
    return True


def _load_all():
    labels, rows = [], []
    if not os.path.isdir(settings.secretaries_dir):
        return [], np.array([])
    for folder in sorted(os.listdir(settings.secretaries_dir)):
        p = os.path.join(settings.secretaries_dir, folder, "features.json")
        if os.path.isfile(p):
            with open(p, "r", encoding="utf-8") as f:
                feats = json.load(f)
            for vec in feats:
                labels.append(folder)
                rows.append(vec)
    if not rows:
        return [], np.array([])
    return labels, np.array(rows)


def retrain():
    global _model

    labels, X = _load_all()
    model_path = _model_path()

    if len(X) == 0:
        _model = None

        if os.path.isfile(model_path):
            os.remove(model_path)

        return None

    if X.ndim == 1:
        X = X.reshape(1, -1)

    n_classes = len(set(labels))

    if n_classes < 2:
        _model = None

        if os.path.isfile(model_path):
            os.remove(model_path)

        return n_classes

    clf = make_pipeline(
        StandardScaler(),
        SVC(
            kernel="rbf",
            C=10,
            gamma="scale",
            probability=True,
            class_weight="balanced",
        ),
    )

    clf.fit(X, np.array(labels))

    _model = clf

    joblib.dump(clf, model_path)

    return n_classes

def load_model():
    global _model
    if _model is None:
        p = _model_path()
        if os.path.isfile(p):
            try:
                _model = joblib.load(p)
            except Exception:
                _model = None


def enroll(name, image_bytes_list):
    feats = [extract_hog(b).tolist() for b in image_bytes_list]
    _save_features(name, feats)
    return retrain()
def delete_secretary(name):
    folder = os.path.join(settings.secretaries_dir, _clean(name))

    if not os.path.isdir(folder):
        return False

    import shutil
    shutil.rmtree(folder)

    retrain()
    return True
def update_secretary(old_name, new_name):
    old_folder = os.path.join(
        settings.secretaries_dir,
        _clean(old_name),
    )

    new_folder = os.path.join(
        settings.secretaries_dir,
        _clean(new_name),
    )

    if not os.path.isdir(old_folder):
        return False, "أمين السر القديم غير موجود"

    if os.path.isdir(new_folder):
        return False, "اسم أمين السر الجديد مستخدم مسبقًا"

    os.rename(old_folder, new_folder)

    retrain()

    return True, None


def count_secretaries():
    d = settings.secretaries_dir
    if not os.path.isdir(d):
        return 0
    return sum(1 for x in os.listdir(d)
               if os.path.isdir(os.path.join(d, x)) and os.path.isfile(os.path.join(d, x, "features.json")))


def predict(image_bytes):
    global _model
    load_model()
    if _model is None:
        return MatchResult(matched=False, confidence=0.0)
    vec = extract_hog(image_bytes).reshape(1, -1)
    proba = _model.predict_proba(vec)[0]
    idx = int(np.argmax(proba))
    conf = float(proba[idx])
    name = _model.classes_[idx]
    matched = conf >= settings.confidence_threshold
    return MatchResult(matched=matched, secretary=name if matched else None, confidence=round(conf, 4))
