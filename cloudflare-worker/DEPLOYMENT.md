# HiddenGems Cloudflare Deployment Guide

## Prerequisites

1. Cloudflare account (free tier works)
2. Node.js 18+ installed
3. Wrangler CLI installed: `npm install -g wrangler`

## Initial Setup

### 1. Login to Cloudflare

```bash
cd cloudflare-worker
wrangler login
```

### 2. Create D1 Database

```bash
# Create the database
wrangler d1 create hidden_gems

# Copy the database_id from the output and update wrangler.toml
# Replace the empty database_id with the one from the output
```

Update `wrangler.toml`:
```toml
[[d1_databases]]
binding = "DB"
database_name = "hidden_gems"
database_id = "YOUR_DATABASE_ID_HERE"  # Paste the ID here
```

### 3. Initialize Database Schema

```bash
# Apply the schema
wrangler d1 execute hidden_gems --file=./schema.sql
```

### 4. Create R2 Bucket

```bash
# Create the images bucket
wrangler r2 bucket create hidden-gems-images
```

### 5. Set Secrets

```bash
# Generate a strong sync token
wrangler secret put APP_SYNC_TOKEN
# When prompted, enter a strong random string (use a password generator)
```

### 6. Install Dependencies

```bash
npm install
```

## Deployment

### Deploy to Production

```bash
# Deploy the worker
wrangler deploy
```

After deployment, you'll get a URL like: `https://hidden-gems.YOUR-SUBDOMAIN.workers.dev`

## Configure R2 Public Access (Optional)

To serve images directly from R2:

1. Go to Cloudflare Dashboard → R2
2. Select `hidden-gems-images` bucket
3. Click "Settings" → "Public Access"
4. Enable public access and note the public URL
5. Update the worker code to use this URL instead of `https://images.hiddengems.app`

Or set up a custom domain:

1. Go to R2 bucket settings
2. Add custom domain: `images.hiddengems.app`
3. Add DNS record in your Cloudflare zone

## Update iOS App Configuration

After deployment, update the iOS app's sync configuration:

1. Open `/Services/Sync/SyncConfiguration.swift`
2. Update the `baseURL`:

```swift
static var baseURL: String {
    #if DEBUG
    return "http://localhost:8787" // for local development
    #else
    return "https://hidden-gems.YOUR-SUBDOMAIN.workers.dev"
    #endif
}
```

3. Update the `syncToken` with the token you set earlier

## Local Development

### Run locally:

```bash
# Start local dev server
wrangler dev

# The server will be available at http://localhost:8787
```

### Test locally with local D1:

```bash
# Create local database for development
wrangler d1 execute hidden_gems --local --file=./schema.sql

# Run with local D1
wrangler dev --local
```

## API Endpoints

Once deployed, your API endpoints will be:

- `POST /api/users/register` - Register anonymous user
- `POST /api/images/upload` - Upload image to R2
- `GET /api/images/:fileName` - Get image from R2
- `POST /api/sync/push` - Push local changes to cloud
- `GET /api/sync/pull` - Pull cloud changes
- `POST /api/group` - Create group
- `POST /api/group/join` - Join group with invite code
- `POST /api/vector/upsert` - Store vector embeddings
- `POST /api/search/semantic` - Semantic search

## Monitoring

View logs in real-time:

```bash
wrangler tail
```

View analytics in Cloudflare Dashboard:
- Workers → Your Worker → Analytics

## Troubleshooting

### Database Connection Issues

```bash
# List your D1 databases
wrangler d1 list

# Query database directly
wrangler d1 execute hidden_gems --command="SELECT * FROM spots LIMIT 5"
```

### R2 Bucket Issues

```bash
# List buckets
wrangler r2 bucket list

# List objects in bucket
wrangler r2 object list --bucket=hidden-gems-images
```

### View Logs

```bash
# Stream logs
wrangler tail

# View specific deployment logs
wrangler tail --format=pretty
```

## Production Checklist

- [ ] D1 database created and schema applied
- [ ] R2 bucket created
- [ ] APP_SYNC_TOKEN secret set (strong, random)
- [ ] Worker deployed successfully
- [ ] R2 custom domain configured (optional but recommended)
- [ ] iOS app updated with production URL
- [ ] Tested sync functionality
- [ ] Tested image upload
- [ ] Monitoring set up

## Cost Estimate (Free Tier)

Cloudflare offers generous free tiers:

- **Workers**: 100,000 requests/day (free)
- **D1**: 5 GB storage, 5 million reads/day (free)
- **R2**: 10 GB storage, 1 million Class A operations/month (free)

For most users starting out, this should be completely free!

## Next Steps

1. Test the API with curl or Postman
2. Update iOS app sync service
3. Test image upload from iOS app
4. Monitor usage in Cloudflare dashboard
5. Set up custom domain for production (optional)

## Support

For issues or questions:
- Cloudflare Workers Docs: https://developers.cloudflare.com/workers/
- D1 Documentation: https://developers.cloudflare.com/d1/
- R2 Documentation: https://developers.cloudflare.com/r2/

