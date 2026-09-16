from google import genai
from .config import settings

_client = None


def get_client():
    global _client
    if _client is None:
        if not settings.gemini_api_key:
            raise RuntimeError("GEMINI_API_KEY غير مضبوطة")
        _client = genai.Client(api_key=settings.gemini_api_key)
    return _client
