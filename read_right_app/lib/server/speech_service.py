import os, time, json, difflib, string
from typing import Dict, Any, List
from dotenv import load_dotenv
import azure.cognitiveservices.speech as speechsdk

load_dotenv()

AZURE_SPEECH_KEY = os.environ.get('AZURE_SPEECH_API_KEY')
AZURE_SPEECH_REGION = os.environ.get('AZURE_REGION')

def assess_pronunciation_from_wav(
    file_path: str,
    reference_text: str,
    language: str = 'en-US'
) -> Dict[str, Any]:
    """
    Runs continuous pronunciation assessment using Azure Speech, based on the official sample.
    - file_path: path to a WAV file
    - reference_text: the expected word/sentence (English)
    - language: BCP-47 language code, here we assume 'en-US'
    """

    if not AZURE_SPEECH_KEY or not AZURE_SPEECH_REGION:
        raise RuntimeError('Missing AZURE_SPEECH_KEY or AZURE_SPEECH_REGION in environment.')

    # --- 1. Create speech + audio config (same pattern as the sample) ---
    speech_config = speechsdk.SpeechConfig(
        subscription=AZURE_SPEECH_KEY,
        region=AZURE_SPEECH_REGION
    )
    audio_config = speechsdk.audio.AudioConfig(filename=file_path)

    enable_miscue = True
    enable_prosody_assessment = True

    # --- 2. Pronunciation config (same as your snippet) ---
    pronunciation_config = speechsdk.PronunciationAssessmentConfig(
        reference_text=reference_text,
        grading_system=speechsdk.PronunciationAssessmentGradingSystem.HundredMark,
        granularity=speechsdk.PronunciationAssessmentGranularity.Phoneme,
        enable_miscue=enable_miscue,
    )
    if enable_prosody_assessment:
        pronunciation_config.enable_prosody_assessment()

    # --- 3. Create recognizer ---
    speech_recognizer = speechsdk.SpeechRecognizer(
        speech_config=speech_config,
        language=language,
        audio_config=audio_config
    )

    pronunciation_config.apply_to(speech_recognizer)

    done = False
    recognized_words: List[speechsdk.PronunciationAssessmentWordResult] = []
    fluency_scores: List[float] = []
    prosody_scores: List[float] = []
    durations: List[int] = []

    # --- 4. Callbacks (these mirror your Python sample) ---

    def stop_cb(evt: speechsdk.SessionEventArgs):
        nonlocal done
        done = True

    def recognized(evt: speechsdk.SpeechRecognitionEventArgs):
        nonlocal recognized_words, fluency_scores, durations, prosody_scores

        if evt.result.reason != speechsdk.ResultReason.RecognizedSpeech:
            return

        pa_result = speechsdk.PronunciationAssessmentResult(evt.result)

        # Collect word-level info + scores
        recognized_words += pa_result.words
        fluency_scores.append(pa_result.fluency_score)
        prosody_scores.append(pa_result.prosody_score)

        json_result = evt.result.properties.get(
            speechsdk.PropertyId.SpeechServiceResponse_JsonResult
        )
        jo = json.loads(json_result)
        nb = jo['NBest'][0]
        durations.append(sum(int(w['Duration']) for w in nb['Words']))

    # Connect callbacks like the sample
    speech_recognizer.recognized.connect(recognized)
    speech_recognizer.session_stopped.connect(stop_cb)
    speech_recognizer.canceled.connect(stop_cb)

    # --- 5. Start & wait (event-style, like your snippet) ---
    speech_recognizer.start_continuous_recognition()
    while not done:
        time.sleep(0.5)
    speech_recognizer.stop_continuous_recognition()

    # --- 6. Prepare reference words (English-only branch of the sample) ---
    reference_words = [
        w.strip(string.punctuation)
        for w in reference_text.lower().split()
        if w.strip(string.punctuation)
    ]

    # --- 7. Handle miscue (insertions/omissions) using difflib (same idea as sample) ---
    if enable_miscue:
        diff = difflib.SequenceMatcher(
            None,
            reference_words,
            [x.word.lower() for x in recognized_words]
        )
        final_words: List[speechsdk.PronunciationAssessmentWordResult] = []
        for tag, i1, i2, j1, j2 in diff.get_opcodes():
            if tag in ['insert', 'replace']:
                for word in recognized_words[j1:j2]:
                    if word.error_type == 'None':
                        # Mutate the underlying error_type (same trick as the sample)
                        word._error_type = 'Insertion'
                    final_words.append(word)
            if tag in ['delete', 'replace']:
                for word_text in reference_words[i1:i2]:
                    word = speechsdk.PronunciationAssessmentWordResult({
                        'Word': word_text,
                        'PronunciationAssessment': {
                            'ErrorType': 'Omission',
                        }
                    })
                    final_words.append(word)
            if tag == 'equal':
                final_words += recognized_words[j1:j2]
    else:
        final_words = recognized_words

    # --- 8. Recompute scores just like the sample ---

    # Whole accuracy (ignore insertions)
    accuracy_scores = [
        w.accuracy_score
        for w in final_words
        if w.error_type != 'Insertion'
    ]
    accuracy_score = (
        sum(accuracy_scores) / len(accuracy_scores)
        if accuracy_scores else 0.0
    )

    # Fluency score: duration-weighted average
    fluency_score = (
        sum(fs * d for fs, d in zip(fluency_scores, durations)) / sum(durations)
        if durations else 0.0
    )

    # Completeness score: how many correct vs reference_words
    if reference_words:
        completeness_score = (
            len([w for w in recognized_words if w.error_type == 'None'])
            / len(reference_words) * 100.0
        )
        completeness_score = min(completeness_score, 100.0)
    else:
        completeness_score = 0.0

    # Prosody: simple average
    prosody_score = (
        sum(prosody_scores) / len(prosody_scores)
        if prosody_scores else 0.0
    )

    # Final pronunciation score with weights (like your sample)
    pron_score = (
        accuracy_score * 0.4 +
        prosody_score * 0.2 +
        fluency_score * 0.2 +
        completeness_score * 0.2
    )

    # Reconstruct transcript from words (rough)
    transcript = ' '.join(w.word for w in recognized_words)

    # --- 9. Build a clean JSON response ---
    words_payload = [
        {
            'word': w.word,
            'accuracy_score': w.accuracy_score,
            'error_type': w.error_type,
        }
        for w in final_words
    ]

    return {
        'transcript': transcript,
        'pron_score': pron_score,
        'accuracy_score': accuracy_score,
        'completeness_score': completeness_score,
        'fluency_score': fluency_score,
        'prosody_score': prosody_score,
        'words': words_payload,
        # A simple correctness decision you can tune
        'correct': pron_score >= 60.0,
        'score': round(pron_score),
    }
