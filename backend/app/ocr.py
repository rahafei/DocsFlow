import asyncio
from io import BytesIO

from PIL import Image
from google.genai import errors

from .gemini_client import get_client


OCR_PROMPT = """أنت محرك تعرف ضوئي (OCR) دقيق متخصص في قراءة الخط العربي اليدوي.

اقرأ كل النص العربي المكتوب بخط اليد في الصورة وأعده نصاً حرفياً كما كُتب بالضبط.

القواعد:

- لا تصحح الإملاء.
- لا تضف كلمات أو معلومات غير موجودة.
- حافظ على ترتيب الأسطر قدر الإمكان.
- تجاهل الأشياء غير النصية.
- إذا كان جزء من الكلمة غير مقروء، حاول قراءته من سياق الخط.
- أعد النص فقط، بدون شرح أو تعليق."""


async def recognize_text(
    image_bytes: bytes,
    mime_type: str = "image/png",
) -> str:
    client = get_client()

    image = Image.open(BytesIO(image_bytes))

    max_retries = 4
    base_delay = 5

    for attempt in range(max_retries):
        try:
            response = client.models.generate_content(
                model="gemini-3.6-flash",
                contents=[
                    image,
                    OCR_PROMPT,
                ],
            )

            return (response.text or "").strip()

        except errors.ServerError as e:
            # نعيد المحاولة فقط مع أخطاء الخادم 5xx
            if getattr(e, "status_code", None) != 503:
                raise

            if attempt == max_retries - 1:
                raise

            delay = base_delay * (2 ** attempt)

            print(
                f"Gemini 503 - إعادة المحاولة "
                f"{attempt + 1}/{max_retries - 1} "
                f"بعد {delay} ثوانٍ..."
            )

            await asyncio.sleep(delay)