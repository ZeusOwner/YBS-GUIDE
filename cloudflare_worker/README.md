# YBS Guide Assistant Worker

Cloudflare Worker proxy for YBS Guide online AI answer enhancement.

## Deployed URL

https://ybs-guide-assistant.myanmarkk479.workers.dev

## Required Secret

Set the OpenAI API key as a Cloudflare Worker secret:

```powershell
cd D:\YBS_Project\ybs_guide\cloudflare_worker
npm.cmd exec wrangler secret put OPENAI_API_KEY
```

Paste the OpenAI API key when Wrangler prompts for it. Do not commit API keys.

## Deploy

```powershell
cd D:\YBS_Project\ybs_guide\cloudflare_worker
npm.cmd run deploy
```

## Flutter Endpoint

The Flutter app defaults to this deployed Worker URL. To override:

```powershell
flutter run --dart-define=YBS_ASSISTANT_WORKER_URL=https://your-worker-url
```
