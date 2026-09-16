import asyncio

from google import genai

from app.config import settings


async def main():
    client = genai.Client(
        api_key=settings.gemini_api_key,
    )

    response = await client.aio.models.generate_content(
        model="gemini-3.6-flash",
        contents="قل مرحبا فقط",
    )

    print("RESPONSE:", response)

asyncio.run(main())