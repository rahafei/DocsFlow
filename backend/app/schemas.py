from typing import Optional
from pydantic import BaseModel


class MatchResult(BaseModel):
    matched: bool
    secretary: Optional[str] = None
    confidence: float = 0.0


class ProcessResult(BaseModel):
    text: str = ""
    secretary: Optional[MatchResult] = None
    docx_path: Optional[str] = None
    docx_url: Optional[str] = None


class EnrollResult(BaseModel):
    name: str
    sample_count: int
    total_secretaries: int
    message: str
