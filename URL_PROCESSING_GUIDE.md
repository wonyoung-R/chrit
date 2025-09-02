# URL Processing System Guide

## Overview
This system processes URLs from YouTube, threads (Twitter/Reddit), and articles to extract summaries and keywords.

## Security Setup

### 1. API Credentials
**IMPORTANT**: Never commit API keys to version control!

1. Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```

2. Add your API keys to `.env`:
   ```
   YOUTUBE_API_KEY=your_actual_youtube_key
   ANTHROPIC_API_KEY=your_actual_anthropic_key
   ```

3. Ensure `.env` is in `.gitignore` (should already be there)

### 2. Regenerate Compromised Keys
If you've accidentally exposed API keys:
1. Go to the respective API console
2. Revoke the exposed keys immediately
3. Generate new keys
4. Update your `.env` file

## Usage

### Processing URLs via API

Send a POST request to `/api/v1/process_url`:

```bash
curl -X POST http://localhost:3000/api/v1/process_url \
  -H "Content-Type: application/json" \
  -d '{"url": "https://youtube.com/watch?v=example"}'
```

### Background Processing

For asynchronous processing, the system uses background jobs:

```ruby
# In your controller or service
ProcessUrlJob.perform_later(knowledge.id)
```

## Content Types

### YouTube Videos
- Extracts video title and thumbnail
- Fetches captions/transcript
- Generates AI summary (~100 characters)
- Extracts relevant keywords

### Thread URLs (Twitter/Reddit)
- Captures main post and relevant replies
- Filters out off-topic discussions
- Combines into coherent summary
- Identifies thread author

### Articles
- Extracts article title and main content
- Captures first image
- Generates concise summary
- Extracts topic keywords

## Keywords System

The system automatically extracts keywords from content:
- #politics #economy #science #ai #technology
- #health #education #entertainment #business #culture
- Maximum 7 keywords per content

## Database Structure

Processed content is stored with:
- `original_url`: The source URL
- `content_type`: youtube/thread/article
- `title`: Extracted or generated title
- `summary`: AI-generated summary
- `keywords`: JSON array of hashtags
- `thumbnail_url`: Image URL if available
- `status`: processing/completed/failed
- `processed_at`: Timestamp of processing

## Development

### Testing the Service

```ruby
# In Rails console
service = UrlProcessorService.new("https://youtube.com/watch?v=example")
result = service.process
puts result
```

### Adding New Content Types

1. Update `identify_content_type` method in `UrlProcessorService`
2. Add new processing method (e.g., `process_podcast_content`)
3. Update keyword extraction logic if needed

## Best Practices

1. **Always use environment variables for API keys**
2. **Implement rate limiting for API calls**
3. **Cache processed content to avoid duplicate API calls**
4. **Use background jobs for time-consuming processing**
5. **Log API errors for debugging**
6. **Implement retry logic for failed API calls**

## Troubleshooting

### API Key Issues
- Verify keys are correctly set in `.env`
- Check API quotas and limits
- Ensure keys have necessary permissions

### Processing Failures
- Check Rails logs: `tail -f log/development.log`
- Verify network connectivity
- Check background job queue: `rails c` then `Delayed::Job.all`

### Content Not Extracting
- Verify URL format is supported
- Check if content is publicly accessible
- Review API response for error messages