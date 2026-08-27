# SIH 2026 Platform Repository

This monorepo contains the baseline architecture for the three primary project components:

```
sih26/
├── app/         # Flutter Mobile Application
├── web/         # Next.js Web Application
└── backend/     # FastAPI Python Service
```

---

## 1. Backend Service (`backend/`)

Built with **FastAPI**, **Pydantic Settings**, and **Uvicorn** with pre-configured CORS middleware.

### Quick Start
```bash
cd backend

# Activate virtual environment
source venv/bin/activate

# Start backend server
uvicorn app.main:app --reload --port 8000
```
- Interactive API Documentation: [http://localhost:8000/docs](http://localhost:8000/docs)
- Health Endpoint: [http://localhost:8000/api/v1/health](http://localhost:8000/api/v1/health)

---

## 2. Web Application (`web/`)

Built with **Next.js 14+ (App Router)**, **TypeScript**, and **Tailwind CSS**. Includes a type-safe `apiClient` configured to talk to the FastAPI backend.

### Quick Start
```bash
cd web

# Install dependencies (if needed)
npm install

# Run development server
npm run dev
```
Open [http://localhost:3000](http://localhost:3000) to view the web dashboard and test API connectivity.

---

## 3. Mobile Application (`app/`)

Built with **Flutter** and Dart `http` package. Features a modular `ApiClient` class with automatic base URL handling (`localhost` vs `10.0.2.2` for Android emulator loopback).

### Quick Start
```bash
cd app

# Run on available device / emulator / web
flutter run
```
- Static analysis: `flutter analyze`
