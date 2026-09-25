import os
import zipfile
import subprocess

html_content = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>YOTRACKEZ - Technical Documentation</title>
<style>
  @import url('https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700&display=swap');
  
  @page {
    margin: 20mm;
    size: A4;
  }
  
  body {
    font-family: 'Outfit', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    line-height: 1.6;
    color: #222;
    background-color: #fff;
    max-width: 850px;
    margin: 0 auto;
    padding: 30px;
  }
  
  .header {
    border-bottom: 2px solid #7B6FFF;
    padding-bottom: 15px;
    margin-bottom: 25px;
  }
  
  h1 {
    color: #111;
    font-size: 28px;
    margin: 0 0 8px 0;
    font-weight: 700;
  }
  
  .subtitle {
    color: #555;
    font-size: 15px;
    margin: 0;
  }
  
  .badge {
    display: inline-block;
    background-color: #f0edff;
    color: #5842ed;
    font-weight: 600;
    font-size: 12px;
    padding: 4px 10px;
    border-radius: 12px;
    margin-top: 8px;
  }
  
  h2 {
    color: #1a1a2e;
    font-size: 20px;
    margin-top: 30px;
    margin-bottom: 12px;
    border-bottom: 1px solid #eee;
    padding-bottom: 6px;
    font-weight: 600;
  }
  
  h3 {
    color: #333;
    font-size: 16px;
    margin-top: 20px;
    margin-bottom: 8px;
    font-weight: 600;
  }
  
  p, li {
    font-size: 14px;
    color: #444;
  }
  
  table {
    width: 100%;
    border-collapse: collapse;
    margin: 15px 0 25px 0;
    font-size: 13.5px;
  }
  
  th, td {
    border: 1px solid #e2e4e8;
    padding: 10px 14px;
    text-align: left;
  }
  
  th {
    background-color: #f7f8fa;
    color: #111;
    font-weight: 600;
  }
  
  tr:nth-child(even) {
    background-color: #fafbfc;
  }
  
  code {
    background-color: #f3f4f6;
    padding: 2px 5px;
    border-radius: 4px;
    font-family: Consolas, monospace;
    font-size: 12.5px;
    color: #d12e66;
  }
  
  pre {
    background-color: #0d1117;
    color: #e6edf3;
    padding: 14px;
    border-radius: 6px;
    overflow-x: auto;
    font-family: Consolas, monospace;
    font-size: 12px;
    line-height: 1.45;
  }
  
  .callout {
    background-color: #f5f3ff;
    border-left: 4px solid #7B6FFF;
    padding: 12px 16px;
    margin: 15px 0;
    border-radius: 0 6px 6px 0;
    font-size: 13.5px;
  }
</style>
</head>
<body>

<div class="header">
  <h1>YOTRACKEZ — Technical Documentation</h1>
  <p class="subtitle">AI-Powered Nutrition & Calorie Tracking Web Application (Vercel Live Deployment)</p>
  <span class="badge">Production Live Build</span>
</div>

<h2>1. System Overview</h2>
<p>
  <strong>YOTRACKEZ</strong> is an intelligent nutrition and wellness web application designed to track meals, compute real-time macronutrient balances, and provide dynamic companion avatar feedback. The user captures or uploads a photo of food, which is securely forwarded through a Vercel serverless proxy to Google's Gemini Vision model for instant, structured nutritional breakdown.
</p>

<h2>2. Tech Stack Summary (Live Deployed Version)</h2>
<table>
  <thead>
    <tr>
      <th>Layer</th>
      <th>Technology</th>
      <th>Role &amp; Details</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><strong>Frontend Web Client</strong></td>
      <td>Flutter 3.x (Dart Web)</td>
      <td>High-performance reactive Web SPA deployed directly to Vercel edge hosting.</td>
    </tr>
    <tr>
      <td><strong>AI / Vision Model</strong></td>
      <td>Google Gemini 2.0 Flash (<code>gemini-2.0-flash</code>)</td>
      <td>Multimodal vision reasoning for food identification, ingredient decomposition, and macronutrient estimation.</td>
    </tr>
    <tr>
      <td><strong>Backend API Proxy</strong></td>
      <td>Vercel Serverless Function (Node.js)</td>
      <td>Secure Edge endpoint (<code>/api/analyze</code>) that proxies image payload to Gemini and secures private API credentials.</td>
    </tr>
    <tr>
      <td><strong>Client Persistence</strong></td>
      <td>SharedPreferences &amp; IndexedDB / Web Storage</td>
      <td>Stores user biometric profiles, daily calorie targets, and logged meal history locally.</td>
    </tr>
    <tr>
      <td><strong>Interactive Avatar</strong></td>
      <td>Rive 2D/2.5D Vector Runtime</td>
      <td>Dynamic companion character adapting across 5 visual wellness states according to net calorie balance.</td>
    </tr>
    <tr>
      <td><strong>Typography &amp; UI</strong></td>
      <td>Google Fonts (Outfit)</td>
      <td>Modern dark-mode aesthetic with custom design tokens (<code>#07080F</code> / <code>#7B6FFF</code>).</td>
    </tr>
  </tbody>
</table>

<div class="callout">
  <strong>Note on Production Scope:</strong> Hardware-dependent mobile modules (hardware pedometer accelerometer and native camera barcode scanning) are intentionally omitted from this web build to ensure zero-dependency cross-browser compatibility on Vercel.
</div>

<h2>3. Architecture Flow</h2>
<ol>
  <li><strong>Image Ingestion:</strong> The user snaps or uploads a meal photo in the web app.</li>
  <li><strong>Preprocessing &amp; Serialization:</strong> Client compresses image into Base64 format and issues a <code>POST</code> request to <code>/api/analyze</code>.</li>
  <li><strong>Secure Proxy Execution:</strong> Vercel serverless handler forwards the request to Google Gemini Vision API with structured JSON schema constraints.</li>
  <li><strong>Nutritional Parse &amp; Render:</strong> Gemini outputs calories, carbs, protein, fats, fiber, and ingredient lists. The client parses and presents interactive macro rings.</li>
  <li><strong>Companion Avatar Adjustment:</strong> Daily net calorie balance recalculates, automatically updating the companion avatar's mood and body state.</li>
</ol>

<h2>4. Core Application Modules &amp; Services</h2>
<table>
  <thead>
    <tr>
      <th>Service / Module</th>
      <th>File Path</th>
      <th>Key Responsibility</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>GeminiFoodService</code></td>
      <td><code>lib/services/gemini_food_service.dart</code></td>
      <td>Transmits image payload to the Vercel backend proxy and deserializes the structured nutrition response.</td>
    </tr>
    <tr>
      <td><code>ImagePreprocessor</code></td>
      <td><code>lib/services/image_preprocessor.dart</code></td>
      <td>Downsamples and optimizes image resolution for swift web upload without quality loss.</td>
    </tr>
    <tr>
      <td><code>MealDbService</code></td>
      <td><code>lib/services/meal_db_service.dart</code></td>
      <td>Manages meal logging, timestamps, calorie tallying, and persistent meal history.</td>
    </tr>
    <tr>
      <td><code>CalorieBalanceEngine</code></td>
      <td><code>lib/services/calorie_balance_engine.dart</code></td>
      <td>Computes net calorie balance (calories consumed vs. expenditure goals) to adjust daily health standing.</td>
    </tr>
    <tr>
      <td><code>BmrCalculator</code></td>
      <td><code>lib/services/bmr_calculator.dart</code></td>
      <td>Calculates Basal Metabolic Rate via standard Mifflin-St Jeor formula based on age, height, weight, and gender.</td>
    </tr>
    <tr>
      <td><code>RecommendationService</code></td>
      <td><code>lib/services/recommendation_service.dart</code></td>
      <td>Generates contextual AI wellness advice and micro-tips based on daily macro ratios.</td>
    </tr>
  </tbody>
</table>

<h2>5. Deployed Application Screens</h2>
<table>
  <thead>
    <tr>
      <th>Screen</th>
      <th>Primary Functionality</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><strong>Splash Screen</strong></td>
      <td>Initializes brand assets, verifies cached user profile, and routes to home.</td>
    </tr>
    <tr>
      <td><strong>Onboarding Screen</strong></td>
      <td>Captures user biometrics (height, weight, age, fitness goal) to compute initial calorie allowances.</td>
    </tr>
    <tr>
      <td><strong>Dashboard / Home Screen</strong></td>
      <td>Central hub displaying daily calorie ring, macro distribution bars, and the animated companion character.</td>
    </tr>
    <tr>
      <td><strong>Result Screen</strong></td>
      <td>Detailed nutritional breakdown showing serving sizes, micro/macro nutrients, and ingredient estimates.</td>
    </tr>
    <tr>
      <td><strong>Meal History Screen</strong></td>
      <td>Chronological ledger of logged meals grouped by calendar date and meal type (Breakfast, Lunch, Dinner, Snack).</td>
    </tr>
    <tr>
      <td><strong>Profile &amp; Settings</strong></td>
      <td>Interface for customizing personal health goals, updating weight/height, and calibrating calorie goals.</td>
    </tr>
  </tbody>
</table>

<h2>6. Backend API Specification</h2>
<pre>
POST /api/analyze
Content-Type: application/json

Request Payload:
{
  "image": "&lt;base64_encoded_jpeg_or_png&gt;",
  "mimeType": "image/jpeg"
}

Successful Response:
{
  "food_name": "Grilled Chicken Salad",
  "serving_size": "1 bowl (approx 350g)",
  "calories": 420.0,
  "carbs": { "name": "Carbohydrates", "amount": 14.0, "unit": "g", "daily_percent": 5.0 },
  "protein": { "name": "Protein", "amount": 48.0, "unit": "g", "daily_percent": 96.0 },
  "fat": { "name": "Fat", "amount": 18.0, "unit": "g", "daily_percent": 23.0 },
  "fiber": { "name": "Fiber", "amount": 6.0, "unit": "g", "daily_percent": 21.0 },
  "ingredients": [
    { "name": "Chicken Breast", "amount": "200g", "calories": 260, "protein": 40, "fat": 5, "carbs": 0 },
    { "name": "Mixed Greens & Olive Oil", "amount": "150g", "calories": 160, "protein": 8, "fat": 13, "carbs": 14 }
  ],
  "health_tip": "High in lean protein, optimal for muscle recovery and satiety."
}
</pre>

</body>
</html>
"""

html_path = r"C:\Users\HP\.gemini\antigravity\scratch\nutri_snap\YOTRACKEZ_Technical_Documentation.html"
with open(html_path, "w", encoding="utf-8") as f:
    f.write(html_content)

print(f"Generated HTML at: {html_path}")

pdf_path = r"C:\Users\HP\.gemini\antigravity\scratch\nutri_snap\YOTRACKEZ_Technical_Documentation.pdf"
desktop_pdf = os.path.expanduser(r"~\Desktop\YOTRACKEZ_Technical_Documentation.pdf")
edge_path = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"

if os.path.exists(edge_path):
    cmd = [
        edge_path,
        "--headless",
        "--disable-gpu",
        f"--print-to-pdf={pdf_path}",
        html_path
    ]
    res = subprocess.run(cmd, capture_output=True)
    if os.path.exists(pdf_path):
        print(f"Generated PDF at: {pdf_path}")
        with open(pdf_path, "rb") as src, open(desktop_pdf, "wb") as dst:
            dst.write(src.read())
        print(f"Copied PDF to Desktop: {desktop_pdf}")
    else:
        print("PDF generation failed:", res.stderr)
