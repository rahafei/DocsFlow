import json
import os
from typing import Optional

from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse

from . import ocr, storage, secretary_model
from .config import settings
from .schemas import EnrollResult, MatchResult, ProcessResult


app = FastAPI(
    title="DocFlow Backend",
    description="OCR عربي يدوي + تعرف على أمين السر + توليد Word",
    version="2.0.0",
)


app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
async def health():
    return {"status": "ok"}


@app.post("/secretaries")
async def create_secretary(name: str = Form(...)):
    created = secretary_model.create_secretary(name)

    if not created:
        raise HTTPException(
            status_code=400,
            detail="أمين السر موجود مسبقًا",
        )

    return {
        "name": name,
        "message": f"تمت إضافة '{name}' بنجاح",
        "total_secretaries": secretary_model.count_secretaries(),
    }


@app.post("/process", response_model=ProcessResult)
async def process(
    files: list[UploadFile] = File(...),
    secretary_name: Optional[str] = Form(None),
):
    if not files:
        raise HTTPException(
            status_code=400,
            detail="أرسل صورة واحدة على الأقل",
        )

    texts = []
    match_results = []

    # معالجة جميع صفحات المستند بالترتيب
    for file in files:
        image_bytes = await file.read()

        # OCR للصفحة الحالية
        text = await ocr.recognize_text(
            image_bytes,
            file.content_type or "image/png",
        )

        texts.append(text)

        # التعرف على أمين السر
        if secretary_name:
            match_results.append(
                MatchResult(
                    matched=True,
                    secretary=secretary_name,
                    confidence=1.0,
                )
            )
        else:
            match_results.append(
                secretary_model.predict(image_bytes)
            )

    # تجميع نصوص الصفحات
    text_parts = []

    for index, page_text in enumerate(texts):
        text_parts.append(
            f"--- الصفحة {index + 1} ---\n{page_text}"
        )

    text = "\n\n".join(text_parts)

    print("OCR FINISHED")
    print("TEXT:", text)

    # تحديد أمين السر النهائي
    if secretary_name:
        match_result = MatchResult(
            matched=True,
            secretary=secretary_name,
            confidence=1.0,
        )

    else:
        matched_results = [
            result
            for result in match_results
            if result.matched and result.secretary
        ]

        if not matched_results:
            match_result = MatchResult(
                matched=False,
                confidence=0.0,
            )

        else:
            secretary_scores = {}

            for result in matched_results:
                name = result.secretary

                if name not in secretary_scores:
                    secretary_scores[name] = []

                secretary_scores[name].append(
                    result.confidence
                )

            best_secretary = max(
                secretary_scores,
                key=lambda name: (
                    len(secretary_scores[name]),
                    sum(secretary_scores[name])
                    / len(secretary_scores[name]),
                ),
            )

            confidences = secretary_scores[best_secretary]

            average_confidence = (
                sum(confidences) / len(confidences)
            )

            match_result = MatchResult(
                matched=True,
                secretary=best_secretary,
                confidence=round(
                    average_confidence,
                    4,
                ),
            )

    # إنشاء Word
    docx_path = None
    docx_url = None

    if match_result.matched and match_result.secretary:
        docx_path = storage.save_document(
            match_result.secretary,
            text,
        )

        docx_url = f"/documents/{docx_path}"

    # Debug
    print("MATCH RESULT:", match_result)
    print("DOCX PATH:", docx_path)
    print("DOCX URL:", docx_url)

    return ProcessResult(
        text=text,
        secretary=match_result,
        docx_path=docx_path,
        docx_url=docx_url,
    )


@app.post("/secretaries/enroll", response_model=EnrollResult)
async def enroll(
    name: str = Form(...),
    files: list[UploadFile] = File(...),
):
    if not files:
        raise HTTPException(
            status_code=400,
            detail="أرسل صورة واحدة على الأقل",
        )

    samples = [await f.read() for f in files]

    secretary_model.enroll(
        name,
        samples,
    )

    return EnrollResult(
        name=name,
        sample_count=len(samples),
        total_secretaries=secretary_model.count_secretaries(),
        message=f"تم تسجيل '{name}' من {len(samples)} عينة",
    )


@app.get("/secretaries")
async def list_secretaries():
    d = settings.secretaries_dir

    result = []

    if os.path.isdir(d):
        for folder in sorted(os.listdir(d)):
            p = os.path.join(
                d,
                folder,
                "features.json",
            )

            if os.path.isfile(p):
                with open(
                    p,
                    "r",
                    encoding="utf-8",
                ) as f:
                    n = len(json.load(f))

                result.append(
                    {
                        "name": folder,
                        "sample_count": n,
                    }
                )

    return {
        "secretaries": result,
    }


@app.put("/secretaries/{old_name}")
async def update_secretary(
    old_name: str,
    new_name: str = Form(...),
):
    updated, error = secretary_model.update_secretary(
        old_name,
        new_name,
    )

    if not updated:
        raise HTTPException(
            status_code=400,
            detail=error,
        )

    return {
        "message": f"تم تعديل '{old_name}' إلى '{new_name}' بنجاح",
        "name": new_name,
    }


@app.delete("/secretaries/{name}")
async def delete_secretary(name: str):
    deleted = secretary_model.delete_secretary(name)

    if not deleted:
        raise HTTPException(
            status_code=404,
            detail="أمين السر غير موجود",
        )

    return {
        "message": f"تم حذف '{name}' بنجاح",
        "total_secretaries": secretary_model.count_secretaries(),
    }


@app.get("/documents/{folder}/{filename}")
async def download(
    folder: str,
    filename: str,
):
    rel = f"{folder}/{filename}"

    try:
        full = storage.resolve_doc_path(rel)

    except ValueError:
        raise HTTPException(
            status_code=400,
            detail="مسار غير مسموح",
        )

    if not os.path.exists(full):
        raise HTTPException(
            status_code=404,
            detail="المستند غير موجود",
        )

    return FileResponse(
        full,
        media_type=(
            "application/vnd.openxmlformats-officedocument."
            "wordprocessingml.document"
        ),
        filename=filename,
    )