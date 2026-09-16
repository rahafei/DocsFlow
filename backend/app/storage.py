import os
import uuid
from datetime import datetime

from .config import settings
from .docx_generator import build_docx


def _clean(name):
    forbidden = {"<", ">", ":", '"', "/", chr(92), "|", "?", "*"}
    name = name.strip()
    name = "".join("_" if c in forbidden else c for c in name)
    return name or "غير_معروف"


def save_document(secretary, text):
    folder = _clean(secretary)
    target_dir = os.path.join(settings.output_dir, folder)
    os.makedirs(target_dir, exist_ok=True)
    stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"scan_{stamp}_{uuid.uuid4().hex[:6]}.docx"
    full = os.path.join(target_dir, filename)
    with open(full, "wb") as f:
        f.write(build_docx(text, title=f"مستند: {secretary}"))
    return os.path.join(folder, filename)


def resolve_doc_path(rel):
    base = os.path.abspath(settings.output_dir)
    full = os.path.abspath(os.path.join(settings.output_dir, rel))
    if not full.startswith(base):
        raise ValueError("مسار غير مسموح")
    return full
