# Deploying Enjoyyy to mmmmichael.com

This guide will help you deploy Enjoyyy to your domain **mmmmichael.com**.

## Architecture Overview

```
┌─────────────────────┐         ┌──────────────────────┐
│                     │         │                      │
│  mmmmichael.com     │  <----> │  enjoyyy.mmmmichael.com  │
│  (Vercel Frontend)  │  HTTPS  │  (Railway Backend)   │
│                     │         │                      │
└─────────────────────┘         └──────────────────────┘
```

## Step 1: Deploy Backend to Railway

### 1.1 Create Railway Project
1. Go to [railway.app](https://railway.app) and sign in
2. Click "New Project" → "Deploy from GitHub repo"
3. Select your `enjoyyy` repository
4. Railway will auto-detect Python and install dependencies

### 1.2 Configure Backend Environment Variables
In Railway dashboard → Variables, add:
```
PORT=automatically-set-by-railway
RAILWAY_ENVIRONMENT=production
```

### 1.3 Deploy Backend
Railway will automatically deploy when you push to GitHub. The backend will be available at:
```
https://your-project-name.up.railway.app
```

### 1.4 Add Custom Domain (enjoyyy.mmmmichael.com)
1. In Railway → Settings → Domains
2. Click "Add Domain"
3. Enter: `enjoyyy.mmmmichael.com`
4. Railway will provide DNS instructions:
   - **Type**: CNAME
   - **Name**: `enjoyyy`
   - **Value**: `your-project-name.up.railway.app`
   - **TTL**: 3600

## Step 2: Configure DNS for Backend

In your DNS provider (where you manage mmmmichael.com):

1. Add a **CNAME record**:
   - **Name/Host**: `enjoyyy`
   - **Value/Target**: `your-project-name.up.railway.app` (from Railway)
   - **TTL**: 3600 (or default)

2. Wait for DNS propagation (5-60 minutes)

3. Verify it works:
   ```bash
   curl https://enjoyyy.mmmmichael.com/
   ```

## Step 3: Deploy Frontend to Vercel

### 3.1 Create Vercel Project
1. Go to [vercel.com](https://vercel.com) and sign in
2. Click "Add New" → "Project"
3. Import your GitHub repository
4. **Important**: Set **Root Directory** to `frontend`
5. Framework Preset: **Next.js** (auto-detected)

### 3.2 Configure Frontend Environment Variables
In Vercel → Settings → Environment Variables, add:
```
NEXT_PUBLIC_API_URL=https://enjoyyy.mmmmichael.com
```

### 3.3 Deploy Frontend
Click "Deploy". Vercel will build and deploy your Next.js app.

### 3.4 Add Custom Domain (mmmmichael.com)
1. In Vercel → Settings → Domains
2. Click "Add Domain"
3. Enter: `mmmmichael.com`
4. Vercel will provide DNS instructions:
   - **Type A**: `76.76.21.21` (Vercel's IP)
   - **Type CNAME**: `cname.vercel-dns.com` (preferred)
   - Or use Vercel's nameservers (recommended)

## Step 4: Configure DNS for Frontend

### Option A: CNAME (Recommended)
Add a **CNAME record**:
- **Name/Host**: `@` (or leave blank for root domain)
- **Value/Target**: `cname.vercel-dns.com`
- **TTL**: 3600

### Option B: A Record
Add an **A record**:
- **Name/Host**: `@`
- **Value/Target**: `76.76.21.21`
- **TTL**: 3600

### Option C: Use Vercel Nameservers (Best)
1. In Vercel → Settings → Domains → mmmmichael.com
2. Click "Nameservers"
3. Copy the nameservers provided
4. Update your domain registrar to use these nameservers

## Step 5: Update CORS Configuration

The backend CORS is already configured in `backend_server.py` to allow:
- `https://mmmmichael.com`
- `https://www.mmmmichael.com`

If you need to add more domains, edit `backend_server.py`:
```python
allowed_origins = [
    "http://localhost:3000",
    "https://mmmmichael.com",
    "https://www.mmmmichael.com",
]
```

## Step 6: Verify Deployment

### Test Backend API
```bash
   curl https://enjoyyy.mmmmichael.com/
# Should return HTML or JSON response
```

### Test Frontend
1. Visit `https://mmmmichael.com` in your browser
2. Try pasting a YouTube URL
3. Verify the mystery link works

### Test Full Flow
1. Create a mystery link on `https://mmmmichael.com`
2. Share the link (e.g., `https://mmmmichael.com?v=abc123`)
3. Open in incognito/private window
4. Verify audio plays and reveals after song ends

## Step 7: SSL/HTTPS

Both Vercel and Railway provide **automatic SSL certificates**:
- ✅ Vercel: Automatic HTTPS for all domains
- ✅ Railway: Automatic HTTPS for custom domains
- No additional configuration needed!

## Troubleshooting

### Backend not accessible
- Check Railway deployment logs
- Verify DNS CNAME record points to Railway URL
- Wait for DNS propagation (can take up to 48 hours)

### Frontend can't connect to backend
- Verify `NEXT_PUBLIC_API_URL` is set correctly in Vercel
- Check browser console for CORS errors
- Verify backend CORS allows `https://mmmmichael.com`

### DNS not working
- Use `dig enjoyyy.mmmmichael.com` or `nslookup enjoyyy.mmmmichael.com` to check DNS
- Verify TTL hasn't cached old records
- Try clearing DNS cache: `sudo systemd-resolve --flush-caches` (Linux)

## Final URLs

After deployment:
- **Frontend**: `https://mmmmichael.com`
- **Backend API**: `https://enjoyyy.mmmmichael.com`
- **Shared Links**: `https://mmmmichael.com?v=abc123`

## Next Steps

1. ✅ Deploy backend to Railway
2. ✅ Configure `enjoyyy.mmmmichael.com` DNS
3. ✅ Deploy frontend to Vercel
4. ✅ Configure `mmmmichael.com` DNS
5. ✅ Test the full application
6. 🎉 Share your mystery music platform!

---

**Need help?** Check the main [DEPLOYMENT.md](DEPLOYMENT.md) for more details.

