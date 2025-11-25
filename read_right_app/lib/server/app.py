import os, tempfile
from fastapi import FastAPI, File, Form, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
from speech_service import assess_pronunciation_from_wav

load_dotenv()
app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],   # tighten this in prod
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.post("/api/assess")
async def assess_pronunciation(
    reference_text: str = Form(...),
    audio: UploadFile = File(...)
):
    """
    Accepts:
      - reference_text: expected English word/sentence
      - audio: WAV file with the student's speech
    Returns:
      - JSON with pron_score, accuracy, completeness, etc.
    """

    # 1. Save uploaded audio to a temp WAV file
    suffix = ".wav" if not audio.filename.endswith(".wav") else ""
    with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
        content = await audio.read()
        tmp.write(content)
        tmp_path = tmp.name

    try:
        # 2. Run the Azure PA logic (your Python snippet turned into a function)
        result = assess_pronunciation_from_wav(
            file_path=tmp_path,
            reference_text=reference_text,
            language='en-US'
        )
    finally:
        # 3. Clean up temp file
        if os.path.exists(tmp_path):
            os.remove(tmp_path)

    return result