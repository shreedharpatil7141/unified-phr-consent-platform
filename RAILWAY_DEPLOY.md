# Railway Deploy (Backend)

## 1) Service Setup
- Create a Railway service from this repo.
- Set **Root Directory** to `backend`.

## 2) Start Command
- Railway will read `backend/Procfile`:
  - `web: uvicorn app.main:app --host 0.0.0.0 --port $PORT`

## 3) Required Environment Variables
- `MONGO_URI` = your MongoDB Atlas URI
- `DB_NAME` = `phr_app` (or your DB name)
- `ACCESS_TOKEN_EXPIRE_MINUTES` = `10080`

## 4) Optional Environment Variables
- `OPENAI_API_KEY` = your key
- `OPENAI_MODEL` = `gpt-5-mini`

## 5) MongoDB Atlas
- Add Railway outbound IPs to Atlas network access.
- For demo-only fallback, temporary `0.0.0.0/0` can be used.

## 6) Verify Deployment
- Open: `https://<your-service>.up.railway.app/docs`
- Test login + consent + upload endpoints from Swagger.

## 7) Flutter App
Run app with Railway backend URL:
```bash
flutter run --dart-define=API_BASE_URL=https://<your-service>.up.railway.app
```
