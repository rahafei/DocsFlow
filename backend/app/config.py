import os

from dotenv import load_dotenv

load_dotenv()


class Settings:
    gemini_api_key: str = os.getenv("GEMINI_API_KEY", "")
    gemini_model: str = os.getenv("GEMINI_MODEL", "gemini-3.6-flash")

    secretaries_dir: str = os.getenv(
        "SECRETARIES_DIR",
        "./secretaries",
    )

    output_dir: str = os.getenv(
        "OUTPUT_DIR",
        "./output",
    )

    confidence_threshold: float = float(
        os.getenv(
            "CONFIDENCE_THRESHOLD",
            "0.55",
        )
    )


settings = Settings()