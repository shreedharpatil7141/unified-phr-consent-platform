# Railway Deployment Guide (Backend)

## 1. Deploy Options on Railway

You can deploy the backend on Railway either from the repository root or by setting the root directory to `backend`. Both configurations are supported.

### Option A: Standard Root Deployment (Recommended)
- Link your GitHub repository in Railway.
- Leave **Root Directory** as `/`.
- Railway will automatically read `railway.json` and build using the root `Dockerfile` or `nixpacks.toml`.

### Option B: Backend Subdirectory Deployment
- If you set **Root Directory** to `backend`:
  - Railway will build using `backend/Dockerfile` or `backend/nixpacks.toml` / `backend/Procfile`.
  - Both options will dynamically listen on `${PORT:-8000}`.

---

## 2. Required Environment Variables

Set these in the **Variables** tab of your Railway service:

| Variable | Description | Example / Recommended Value |
|---|---|---|
| `MONGO_URI` | MongoDB Atlas connection string | `mongodb+srv://<user>:<password>@cluster0.xxx.mongodb.net/?retryWrites=true&w=majority` |
| `DB_NAME` | Database name | `phr_app` |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | JWT expiration | `10080` (7 days) |

### Optional Environment Variables (For AI Features)
| Variable | Description | Example Value |
|---|---|---|
| `OPENAI_API_KEY` | OpenAI API Key for insight generation | `sk-...` |
| `OPENAI_MODEL` | Model name | `gpt-4o-mini` or `gpt-5-mini` |

---

## 3. MongoDB Atlas Network Configuration

> [!IMPORTANT]
> Railway containers use dynamic outbound IP addresses. In MongoDB Atlas:
> 1. Go to **Network Access** > **IP Access List**.
> 2. Add `0.0.0.0/0` (Allow Access from Anywhere) or your dedicated VPC/Peering if configured.
> 3. Ensure your MongoDB Atlas user has read & write permissions on `phr_app` database.

---

## 4. Verification & Health Check

After deployment completes:
- **Base health check**: `https://<your-service>.up.railway.app/healthz` (returns `{"status":"healthy"}`)
- **Root service info**: `https://<your-service>.up.railway.app/` (returns `{"status":"ok","service":"unified-phr-backend"}`)
- **Swagger Documentation**: `https://<your-service>.up.railway.app/docs`

---

## 5. Connecting Frontend Applications

### Doctor Dashboard (React Web)
Set the environment variable in your dashboard deployment (Render/Vercel/Netlify):
```env
REACT_APP_API_BASE_URL=https://<your-service>.up.railway.app
```

### Patient App (Flutter)
Run or build the Flutter app passing your backend URL:
```bash
flutter run --dart-define=API_BASE_URL=https://<your-service>.up.railway.app
```
For release APK:
```bash
flutter build apk --dart-define=API_BASE_URL=https://<your-service>.up.railway.app
```
