# Unified PHR Deployment Guide

This project consists of three main components:
1. **Backend** (FastAPI / Python)
2. **Doctor Dashboard** (React Web App)
3. **Patient Mobile App** (Flutter)

---

## 1. Backend Deployment

The backend can be deployed on **Railway**, **Render**, **Fly.io**, or any container platform (Docker).

### Environment Variables
Configure the following variables in your hosting provider's dashboard:

| Variable | Required | Description | Example |
|---|---|---|---|
| `MONGO_URI` | Yes | MongoDB Atlas connection string with credentials | `mongodb+srv://user:pass@cluster0.xxx.mongodb.net/?retryWrites=true&w=majority` |
| `DB_NAME` | Yes | Database name | `phr_app` |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | No | Token expiration in minutes | `10080` (default 7 days) |
| `OPENAI_API_KEY` | Optional | OpenAI key for AI insights | `sk-...` |
| `OPENAI_MODEL` | Optional | Model identifier | `gpt-4o-mini` |

### Deploy on Railway
See [RAILWAY_DEPLOY.md](RAILWAY_DEPLOY.md).

### Deploy on Render
1. Create a new **Web Service** connected to your repo.
2. If using Blueprint, Render will auto-detect `render.yaml`.
3. Manual configuration:
   - **Root Directory**: `backend`
   - **Build Command**: `pip install -r requirements.txt`
   - **Start Command**: `uvicorn app.main:app --host 0.0.0.0 --port $PORT`
   - **Health Check Path**: `/healthz`

### Deploy with Docker Locally or on VPS
```bash
# Build root Dockerfile
docker build -t unified-phr-backend .

# Run container
docker run -d -p 8000:8000 \
  -e MONGO_URI="<your-atlas-uri>" \
  -e DB_NAME="phr_app" \
  --name phr-backend \
  unified-phr-backend
```

---

## 2. Doctor Dashboard Deployment (React)

The doctor dashboard can be hosted on **Render Static Sites**, **Vercel**, **Netlify**, or **GitHub Pages**.

### Environment Variables
| Variable | Value |
|---|---|
| `REACT_APP_API_BASE_URL` | Your deployed backend URL (e.g., `https://unified-phr-backend.up.railway.app`) |

### Build & Deploy Settings
- **Root Directory**: `doctor-dashboard`
- **Build Command**: `npm ci && npm run build`
- **Publish Directory**: `build`

---

## 3. Patient App (Flutter)

Build the Flutter app targeting your deployed backend API:

```bash
cd frontend/patient-app

# Run in debug/profile mode with live backend
flutter run --dart-define=API_BASE_URL=https://<your-backend-domain>

# Build Android APK
flutter build apk --release --dart-define=API_BASE_URL=https://<your-backend-domain>
```

---

## 4. Common Troubleshooting

### 1. 502 Bad Gateway / Port Binding Error
- Ensure the start command uses dynamic `${PORT:-8000}` rather than fixed `8000`.
- All `Procfile`, `nixpacks.toml`, and `Dockerfile` configurations in this repository are pre-configured to bind dynamically to `$PORT`.

### 2. MongoDB Timeout / ServerSelectionTimeoutError
- MongoDB Atlas container network access must whitelist `0.0.0.0/0` (in Atlas: **Network Access** > **Add IP Address** > **Allow Access from Anywhere**).
- Double check special characters in the database password inside `MONGO_URI` (must be URL encoded if containing `@`, `:`, `/`, etc.).

### 3. Health Check Failures
- The backend provides two dedicated endpoints:
  - `/healthz` -> `{"status": "healthy"}`
  - `/` -> `{"status": "ok", "service": "unified-phr-backend"}`
  - `/docs` -> OpenAPI Swagger UI
