# CloudFront Function for Directory Index Handling

This CloudFront Function automatically appends `index.html` to directory requests, allowing Hugo's directory-based URLs to work correctly.

## Problem

Hugo generates static sites with directory structure:
```
/about/index.html
/music/index.html
/live/index.html
```

When users visit `https://obscvrat.fi/about/`, CloudFront tries to serve `/about/` from S3, which returns 403 Forbidden because S3 doesn't serve directory listings.

## Solution

A CloudFront Function rewrites the request URI to append `index.html` before forwarding to S3.

## Function Code

File: `infrastructure/aws/cloudfront-function-index.js`

```javascript
function handler(event) {
    var request = event.request;
    var uri = request.uri;
    
    // Check if URI ends with '/'
    if (uri.endsWith('/')) {
        request.uri += 'index.html';
    }
    // Check if URI has no file extension
    else if (!uri.includes('.')) {
        request.uri += '/index.html';
    }
    
    return request;
}
```

## Setup Instructions

### Step 1: Create CloudFront Function

1. Go to **AWS Console** → **CloudFront** → **Functions** (left sidebar)
2. Click **Create function**
3. **Name:** `append-index-html`
4. **Runtime:** `cloudfront-js-2.0`
5. Click **Create function**

### Step 2: Add Function Code

1. In the function editor, paste the code above
2. Click **Save changes**
3. Click **Test** tab (optional - to test the function)
4. Click **Publish** tab
5. Click **Publish function**

### Step 3: Associate with CloudFront Distribution

1. Go to **CloudFront** → **Distributions**
2. Select your distribution
3. Click **Behaviors** tab
4. Select the default behavior (`*`)
5. Click **Edit**
6. Scroll to **Function associations**
7. **Viewer request:** Select `append-index-html` from dropdown
8. Click **Save changes**
9. Wait 5-10 minutes for CloudFront to deploy the change

### Step 4: Verify

Test that directory URLs work:

```bash
# Should return 200 OK
curl -I https://obscvrat.fi/about/

# Should also work without trailing slash
curl -I https://obscvrat.fi/about

# Root should still work
curl -I https://obscvrat.fi/
```

## How It Works

**Request flow:**

1. User visits `https://obscvrat.fi/about/`
2. CloudFront receives request for `/about/`
3. Function runs and rewrites URI to `/about/index.html`
4. CloudFront fetches `/about/index.html` from S3
5. S3 returns the file
6. CloudFront serves it to the user

**Edge cases handled:**

- `/about/` → `/about/index.html` (trailing slash)
- `/about` → `/about/index.html` (no trailing slash)
- `/` → `/index.html` (root)
- `/style.css` → `/style.css` (files with extensions unchanged)
- `/images/logo.png` → `/images/logo.png` (unchanged)

## Cost

CloudFront Functions are very cheap:
- **Free tier:** 2 million invocations per month
- **After free tier:** $0.10 per 1 million invocations

For a typical website with 10,000 page views per month, this costs **$0.00** (within free tier).

## Alternative: Lambda@Edge

Lambda@Edge is more powerful but more expensive and complex. CloudFront Functions are sufficient for this use case.

## Troubleshooting

### Function not working

1. Check function is published (not just saved)
2. Verify function is associated with viewer request (not viewer response)
3. Wait 5-10 minutes for CloudFront deployment
4. Check CloudFront distribution status is "Deployed"

### Still getting 403 errors

1. Check S3 bucket policy allows CloudFront OAI access
2. Verify files exist in S3: `aws s3 ls s3://obscvratfi/about/`
3. Check CloudFront error logs in CloudWatch

## Related Documentation

- [CloudFront Functions Documentation](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/cloudfront-functions.html)
- [infrastructure/README.md](README.md) - Main infrastructure setup
- [docs/DEPLOYMENT.md](../docs/DEPLOYMENT.md) - Deployment guide
