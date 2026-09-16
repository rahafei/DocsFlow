# DocsFlow 📄✨

**DocsFlow** is an AI-powered document processing application designed to convert handwritten Arabic documents into editable Word files.

The system combines a Flutter mobile application with a FastAPI backend to process handwritten documents, recognize the secretary based on handwriting samples, extract the written content using AI-powered OCR, and generate an editable Word document.

---

## 🎯 Project Overview

DocsFlow was developed to help accounting and warehouse offices digitize handwritten documents and reduce the manual effort required to rewrite them digitally.

The application allows users to:

* Scan or upload handwritten documents.
* Register secretaries and add handwriting samples.
* Automatically identify the secretary who wrote a document.
* Extract Arabic handwritten text using AI-powered OCR.
* Generate an editable `.docx` Word document from the processed text.

---

## ✨ Key Features

### 📱 Flutter Application

* Modern Arabic-friendly mobile interface.
* Document scanning and image selection.
* Secretary management.
* Local data persistence.
* Communication with the backend API.
* Displaying processed document results.

### 🤖 AI & Handwriting Recognition

* Arabic handwriting OCR.
* Handwriting feature extraction.
* Secretary identification based on enrolled handwriting samples.
* Confidence-based matching.
* Automatic model retraining when new handwriting samples are added.

### 📄 Word Generation

Processed handwritten documents are converted into editable Microsoft Word (`.docx`) files.

---

## 🔄 How It Works

```text
User
  ↓
Flutter Application
  ↓
Upload / Scan Handwritten Document
  ↓
FastAPI Backend
  ↓
┌───────────────────────────┐
│ Arabic OCR                │
│ Handwriting Recognition   │
└───────────────────────────┘
  ↓
Secretary Identification
  ↓
Extracted Text
  ↓
Editable Word Document
```

---

## 🛠️ Tech Stack

### Frontend

* Flutter
* Dart
* SQLite
* SharedPreferences

### Backend

* Python
* FastAPI
* Uvicorn
* scikit-learn
* scikit-image
* python-docx

### AI

* Google Gemini API
* Arabic OCR
* HOG-based handwriting feature extraction
* SVM classification

---

## 👩🏻‍💻 Team Contributions

DocsFlow was developed collaboratively, with responsibilities divided across the frontend, backend, AI, and integration work.

### Rahaf Mohammed Baras

**Flutter Frontend & Integration**

* Designed and implemented the Flutter frontend.
* Built the main application screens and user interface.
* Implemented secretary management and related user flows.
* Integrated local data persistence.
* Connected the Flutter application with the FastAPI backend.
* Integrated the frontend with the backend APIs for document processing and secretary management.

### Maria Zaid Qamzawi

**Backend & AI**

* Developed the FastAPI backend architecture.
* Implemented the Arabic OCR processing pipeline.
* Developed handwriting feature extraction and secretary recognition.
* Implemented secretary enrollment and model retraining.
* Implemented Word document generation.
* Integrated the AI services required for document processing.

---

## 📁 Project Structure

```text
DocsFlow/
│
├── lib/                    # Flutter application
│   ├── core/
│   ├── models/
│   ├── screens/
│   └── services/
│
├── backend/                # FastAPI backend
│   ├── app/
│   │   ├── ocr.py
│   │   ├── secretary_model.py
│   │   ├── features.py
│   │   ├── docx_generator.py
│   │   └── main.py
│   ├── requirements.txt
│   └── run.py
│
├── assets/
├── android/
├── ios/
├── pubspec.yaml
└── README.md
```

---

## 🔐 Environment Variables

The backend uses environment variables for configuration and API credentials.

For security, real API keys and generated files are **not included in this repository**.

Use the provided example file:

```text
backend/.env.example
```

and configure the required environment variables locally.

---

## 🚀 Running the Project

### Flutter

Install the Flutter dependencies:

```bash
flutter pub get
```

Then run the application on a connected device or emulator:

```bash
flutter run
```

### Backend

Create and activate a Python virtual environment, then install the required dependencies:

```bash
pip install -r backend/requirements.txt
```

Configure the required environment variables and start the FastAPI server:

```bash
uvicorn app.main:app --reload
```

---

## 📌 Project Status

DocsFlow is a graduation project developed as a collaborative Flutter, backend, and AI-based document processing system.

The project demonstrates the integration of:

**Mobile Development + REST APIs + AI OCR + Handwriting Recognition + Document Generation**

---

## 👥 Team

**Rahaf Mohammed Baras**
Flutter Frontend & Backend Integration

**Maria Zaid Qamzawi**
Backend & AI Development
