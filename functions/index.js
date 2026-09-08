const { onRequest } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");

exports.analyzeFood = onRequest(
  {
    cors: true,
    secrets: ["GEMINI_API_KEY"],
  },
  async (req, res) => {
    // Handle CORS preflight
    if (req.method === "OPTIONS") {
      res.set("Access-Control-Allow-Origin", "*");
      res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
      res.set("Access-Control-Allow-Headers", "Content-Type");
      return res.status(204).send("");
    }

    if (req.method !== "POST") {
      return res.status(405).json({ error: "Method Not Allowed" });
    }

    try {
      // Retrieve server secret or fallback env variable
      const apiKey = process.env.GEMINI_API_KEY;
      if (!apiKey) {
        logger.error("GEMINI_API_KEY secret missing on server");
        return res.status(500).json({ error: "Server API Key not configured" });
      }

      const requestBody = req.body;
      const model = "gemini-2.5-flash";
      const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;

      const response = await fetch(url, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: typeof requestBody === "string" ? requestBody : JSON.stringify(requestBody),
      });

      const data = await response.json();
      res.set("Access-Control-Allow-Origin", "*");
      return res.status(response.status).json(data);
    } catch (err) {
      logger.error("Proxy exception:", err);
      res.set("Access-Control-Allow-Origin", "*");
      return res.status(500).json({ error: err.message || "Internal server error" });
    }
  }
);
