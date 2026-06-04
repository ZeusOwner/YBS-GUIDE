const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type",
};

const DEFAULT_DAILY_AI_LIMIT = 5;
const OUT_OF_SCOPE_ANSWER =
  "I can only help with Yangon Bus Service routes, stops, fares, schedules, and trip planning.";
const AI_INSTRUCTIONS =
  "You are YBS Guide Assistant for Yangon bus passengers. Only answer questions about Yangon Bus Service routes, stops, fares, schedules, and trip planning. Rewrite the provided local route result in clear, concise English or Burmese based on the user's language. Use only the provided local route candidates and offline answer. Do not invent routes, stops, fares, schedules, coordinates, or live arrival times. If data is limited, say so plainly. If the question is unrelated to YBS, refuse briefly.";
const YBS_TOPIC_TERMS = [
  "ybs",
  "bus",
  "route",
  "stop",
  "fare",
  "schedule",
  "yangon",
  "sule",
  "pagoda",
  "downtown",
  "insein",
  "hlaing",
  "thaketa",
  "\u101b\u1014\u103a\u1000\u102f\u1014\u103a",
  "\u1018\u1010\u103a\u1005\u103a",
  "\u1000\u102c\u1038",
  "\u101c\u1019\u103a\u1038\u1000\u103c\u1031\u102c\u1004\u103a\u1038",
  "\u1019\u103e\u1010\u103a\u1010\u102d\u102f\u1004\u103a",
  "\u1006\u1030\u1038\u101c\u1031",
  "\u101e\u103d\u102c\u1038",
  "\u1005\u102e\u1038",
  "\u1000\u103b\u1015\u103a",
];

export default {
  async fetch(request, env) {
    if (request.method === "OPTIONS") {
      return new Response(null, { headers: corsHeaders });
    }
    if (request.method !== "POST") {
      return json({ error: "Method not allowed" }, 405);
    }

    let body;
    try {
      body = await request.json();
    } catch {
      return json({ error: "Invalid JSON body" }, 400);
    }

    const offlineAnswer = safeText(body.offlineAnswer);
    if (!offlineAnswer) {
      return json({ error: "offlineAnswer is required" }, 400);
    }
    if (!isYbsRelated(body)) {
      return json({
        answer: OUT_OF_SCOPE_ANSWER,
        confidence: "out-of-scope",
      });
    }

    const quota = await checkDailyQuota(request, env);
    if (!quota.allowed) {
      return json({
        answer: offlineAnswer,
        confidence: "offline-daily-limit",
        dailyLimitReached: true,
        dailyLimit: quota.limit,
      });
    }
    if (!env.GEMINI_API_KEY && !env.OPENAI_API_KEY) {
      return json({
        answer: offlineAnswer,
        confidence: "offline-no-ai-provider",
        dailyLimit: quota.limit,
        dailyUsed: quota.used,
      });
    }

    const prompt = buildPrompt(body);
    if (env.GEMINI_API_KEY) {
      const gemini = await enhanceWithGemini(env, prompt);
      if (gemini.answer) {
        return json({
          answer: gemini.answer,
          confidence: "local-data-enhanced",
          provider: "gemini",
          dailyLimit: quota.limit,
          dailyUsed: quota.used,
        });
      }
      console.log("Gemini request failed", gemini.error);
    }

    if (env.OPENAI_API_KEY) {
      const openai = await enhanceWithOpenAi(env, prompt);
      if (openai.answer) {
        return json({
          answer: openai.answer,
          confidence: "local-data-enhanced",
          provider: "openai",
          dailyLimit: quota.limit,
          dailyUsed: quota.used,
        });
      }
      console.log("OpenAI request failed", openai.error);
    }

    return json({
      answer: offlineAnswer,
      confidence: "online-failed",
      onlineEnhancementFailed: true,
      dailyLimit: quota.limit,
      dailyUsed: quota.used,
    });
  },
};

async function enhanceWithGemini(env, prompt) {
  const model = env.GEMINI_MODEL || "gemini-2.5-flash";
  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,
    {
      method: "POST",
      headers: {
        "x-goog-api-key": env.GEMINI_API_KEY,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        contents: [
          {
            role: "user",
            parts: [
              {
                text: `${AI_INSTRUCTIONS}\n\nLocal context JSON:\n${prompt}`,
              },
            ],
          },
        ],
        generationConfig: {
          temperature: 0.3,
          maxOutputTokens: 450,
        },
      }),
    },
  );

  if (!response.ok) {
    return { error: await response.text() };
  }

  const data = await response.json();
  return { answer: extractGeminiText(data) };
}

async function enhanceWithOpenAi(env, prompt) {
  const response = await fetch("https://api.openai.com/v1/responses", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${env.OPENAI_API_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: env.OPENAI_MODEL || "gpt-4o-mini",
      instructions: AI_INSTRUCTIONS,
      input: prompt,
      max_output_tokens: 450,
    }),
  });

  if (!response.ok) {
    return { error: await response.text() };
  }

  const data = await response.json();
  return { answer: extractOpenAiText(data) };
}

async function checkDailyQuota(request, env) {
  const limit =
    Number.parseInt(env.DAILY_AI_LIMIT || "", 10) || DEFAULT_DAILY_AI_LIMIT;
  if (!env.YBS_RATE_LIMITS) {
    return { allowed: true, limit, used: 0 };
  }

  const date = new Date().toISOString().slice(0, 10);
  const clientIp =
    request.headers.get("CF-Connecting-IP") ||
    request.headers.get("x-forwarded-for") ||
    "unknown";
  const clientHash = await sha256Hex(clientIp);
  const key = `ai:${date}:${clientHash}`;
  const current = Number.parseInt(
    (await env.YBS_RATE_LIMITS.get(key)) || "0",
    10,
  );
  if (current >= limit) {
    return { allowed: false, limit, used: current };
  }
  const next = current + 1;
  await env.YBS_RATE_LIMITS.put(key, String(next), { expirationTtl: 172800 });
  return { allowed: true, limit, used: next };
}

function isYbsRelated(body) {
  const routes = Array.isArray(body.candidateRoutes) ? body.candidateRoutes : [];
  const routeText = routes
    .slice(0, 4)
    .map((route) =>
      [
        route.routeNumber,
        route.nameEn,
        route.nameMm,
        route.fromStop,
        route.toStop,
        route.startStopEn,
        route.endStopEn,
      ]
        .filter(Boolean)
        .join(" "),
    )
    .join(" ");
  const text = [body.question, body.destination, body.nearestStop, routeText]
    .map(safeText)
    .join(" ")
    .toLowerCase();
  return YBS_TOPIC_TERMS.some((term) => text.includes(term.toLowerCase()));
}

function buildPrompt(body) {
  const routes = Array.isArray(body.candidateRoutes)
    ? body.candidateRoutes.slice(0, 4)
    : [];
  return JSON.stringify({
    userQuestion: safeText(body.question),
    languageCode: safeText(body.languageCode) || "en",
    nearestStop: safeText(body.nearestStop),
    destination: safeText(body.destination),
    candidateRoutes: routes,
    offlineAnswer: safeText(body.offlineAnswer),
    privacyNote: "Raw GPS is not included. Nearest stop is computed on device.",
  });
}

function extractGeminiText(data) {
  const parts = data?.candidates?.[0]?.content?.parts || [];
  return parts
    .map((part) => safeText(part.text))
    .filter(Boolean)
    .join("\n")
    .trim();
}

function extractOpenAiText(data) {
  if (typeof data.output_text === "string") {
    return data.output_text.trim();
  }
  const parts = [];
  for (const item of data.output || []) {
    for (const content of item.content || []) {
      if (content.type === "output_text" && content.text) {
        parts.push(content.text);
      }
    }
  }
  return parts.join("\n").trim();
}

function safeText(value) {
  return typeof value === "string" ? value.trim() : "";
}

async function sha256Hex(value) {
  const bytes = new TextEncoder().encode(value);
  const hash = await crypto.subtle.digest("SHA-256", bytes);
  return [...new Uint8Array(hash)]
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

function json(value, status = 200) {
  return new Response(JSON.stringify(value), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
