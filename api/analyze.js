export default async function handler(req, res) {
  // Handle CORS headers
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");

  if (req.method === "OPTIONS") {
    return res.status(200).end();
  }

  if (req.method === "GET") {
    return res.status(200).json({
      status: "ok",
      service: "YOTRACKEZ AI Vision Proxy",
      version: "2.4",
      operational: true
    });
  }

  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method Not Allowed" });
  }

  try {
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      return res.status(500).json({ error: "Server API key not configured." });
    }

    const models = ["gemini-2.5-flash", "gemini-2.0-flash", "gemini-1.5-flash"];
    let lastData = null;
    let lastStatus = 500;

    for (const model of models) {
      const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;
      const bodyData = typeof req.body === "string" ? req.body : JSON.stringify(req.body);

      const response = await fetch(url, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: bodyData,
      });

      lastData = await response.json();
      lastStatus = response.status;

      if (response.ok) {
        return res.status(200).json(lastData);
      }
    }

    return res.status(lastStatus).json(lastData);
  } catch (error) {
    return res.status(500).json({ error: error.message || "Internal Proxy Error" });
  }
}
