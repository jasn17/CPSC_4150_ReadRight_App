# Backend Quickstart

Steps to get the pronunciation backend running locally.

## 1) Install Python dependencies
From `read_right_app/lib/server`:
```bash
python -m venv .venv
source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -r req.txt
```

## 2) Flutter dependencies (frontend)
From `read_right_app/` (project root):
```bash
flutter pub get          # or: flutter pub upgrade
```

## 3) Environment variables
Export your Azure Speech credentials before starting the server:
```bash
export AZURE_SPEECH_KEY="<your-key>"
export AZURE_SPEECH_REGION="<your-region>"   # e.g. eastus
```

## 4) Run the FastAPI server
From `read_right_app/lib/server`:
```bash
uvicorn app:app --reload --port 8000
```

Notes:
- Android emulator reaches the host machine at `http://10.0.2.2:8000`.
- If you change ports, update the frontend `sendForPronunciationAssessment` URL accordingly.
