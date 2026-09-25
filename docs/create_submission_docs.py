import os
import subprocess

desktop = os.path.expanduser(r"~\Desktop")
edge_path = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"

tech_doc_html = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>YOTRACKEZ - Technical Documentation (Live Deployment)</title>
<style>
  @page { margin: 15mm; size: A4; }
  body {
    font-family: 'Segoe UI', Arial, sans-serif;
    line-height: 1.6;
    color: #1a1a1a;
    padding: 25px;
    max-width: 800px;
    margin: 0 auto;
  }
  .header {
    border-bottom: 3px solid #7B6FFF;
    padding-bottom: 12px;
    margin-bottom: 20px;
  }
  h1 { font-size: 24px; color: #0d1117; margin: 0 0 6px 0; }
  .badge {
    background: #eef0ff;
    color: #5b46e8;
    font-weight: bold;
    padding: 4px 10px;
    border-radius: 12px;
    font-size: 12px;
  }
  h2 { font-size: 17px; color: #24292f; margin-top: 24px; border-bottom: 1px solid #eaecef; padding-bottom: 5px; }
  table { width: 100%; border-collapse: collapse; margin: 12px 0 20px 0; font-size: 13px; }
  th, td { border: 1px solid #d0d7de; padding: 8px 12px; text-align: left; }
  th { background-color: #f6f8fa; font-weight: 600; }
  tr:nth-child(even) { background-color: #fbfcfd; }
  code { background: #f3f4f6; padding: 2px 5px; border-radius: 4px; font-family: Consolas, monospace; font-size: 12px; color: #cf222e; }
  pre { background: #0d1117; color: #e6edf3; padding: 12px; border-radius: 6px; font-size: 12px; overflow-x: auto; }
  .info-box { background: #f0f4ff; border-left: 4px solid #7B6FFF; padding: 10px 14px; margin: 12px 0; font-size: 13px; }
</style>
</head>
<body>

<div class="header">
  <h1>YOTRACKEZ — Technical Documentation</h1>
  <p style="margin: 4px 0 8px 0; color: #57606a;">Production Live Deployment on Vercel</p>
  <span class="badge">Live Web Build</span>
</div>

<div class="info-box">
  <strong>Live Application Endpoint:</strong> <code>https://nutrisnapproxy.vercel.app</code><br>
  <strong>Scope:</strong> Includes strictly the live web application, Vercel serverless proxy, and Gemini vision integration.
</div>

<h2>1. Tech Stack Summary</h2>
<table>
  <thead>
    <tr>
      <th>Layer</th>
      <th>Technology</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><strong>Frontend</strong></td>
      <td>Vanilla HTML5, CSS3, JavaScript</td>
      <td>Lightweight single-page web client (Scan, Dashboard, History, Avatar).</td>
    </tr>
    <tr>
      <td><strong>AI / Vision API</strong></td>
      <td>Google Gemini API (Flash series)</td>
      <td>Automated tier fallback: <code>gemini-2.5-flash</code> &rarr; <code>gemini-2.0-flash</code> &rarr; <code>gemini-1.5-flash</code>.</td>
    </tr>
    <tr>
      <td><strong>Backend Proxy</strong></td>
      <td>Vercel Serverless Function (Node.js)</td>
      <td>Endpoint: <code>POST /api/analyze</code>. Secures Gemini API key and coordinates prompt formatting.</td>
    </tr>
    <tr>
      <td><strong>Client Storage</strong></td>
      <td>Browser <code>localStorage</code></td>
      <td>Local persistence for logged meals, daily goals, water tracking, and user state.</td>
    </tr>
    <tr>
      <td><strong>Design & Fonts</strong></td>
      <td>Google Fonts (Outfit, Inter)</td>
      <td>Modern dark-themed UI (<code>#07080F</code> background, <code>#7B6FFF</code> accent).</td>
    </tr>
  </tbody>
</table>

<h2>2. Live Web Features</h2>
<ul>
  <li><strong>Scan &amp; AI Analysis:</strong> User uploads or drags an image of food. The proxy sends the image to Gemini Vision, receiving structured nutrition estimates (calories, protein, carbs, fats, fiber, ingredients).</li>
  <li><strong>Dashboard:</strong> Interactive circular daily calorie tracker, macro progress bars, water intake logger, and activity tracking.</li>
  <li><strong>Meal History:</strong> Chronological log of recorded meals with timestamp, portion details, and nutritional breakdown.</li>
  <li><strong>Cyber Avatar &amp; XP:</strong> Gamified level progression and XP counter rewarding consistent meal and hydration logging.</li>
</ul>

<h2>3. Backend API Contract (Vercel Serverless)</h2>
<p><strong>Endpoint:</strong> <code>POST /api/analyze</code></p>
<pre>
// Request Payload
{
  "image": "&lt;base64_encoded_image_data&gt;",
  "mimeType": "image/jpeg"
}

// Successful Response
{
  "food_name": "Paneer Butter Masala with Naan",
  "serving_size": "1 plate (approx 350g)",
  "calories": 520.0,
  "carbs": { "name": "Carbohydrates", "amount": 45.0, "unit": "g" },
  "protein": { "name": "Protein", "amount": 18.0, "unit": "g" },
  "fat": { "name": "Fat", "amount": 30.0, "unit": "g" },
  "fiber": { "name": "Fiber", "amount": 4.5, "unit": "g" }
}
</pre>

</body>
</html>
"""

er_doc_html = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>YOTRACKEZ - ER Diagram & Data Model (Live)</title>
<style>
  @page { margin: 15mm; size: A4; }
  body {
    font-family: 'Segoe UI', Arial, sans-serif;
    line-height: 1.6;
    color: #1a1a1a;
    padding: 25px;
    max-width: 800px;
    margin: 0 auto;
  }
  .header {
    border-bottom: 3px solid #7B6FFF;
    padding-bottom: 12px;
    margin-bottom: 20px;
  }
  h1 { font-size: 24px; color: #0d1117; margin: 0 0 6px 0; }
  h2 { font-size: 17px; color: #24292f; margin-top: 24px; border-bottom: 1px solid #eaecef; padding-bottom: 5px; }
  .badge { background: #eef0ff; color: #5b46e8; font-weight: bold; padding: 4px 10px; border-radius: 12px; font-size: 12px; }
  table { width: 100%; border-collapse: collapse; margin: 12px 0 20px 0; font-size: 13px; }
  th, td { border: 1px solid #d0d7de; padding: 8px 12px; text-align: left; }
  th { background-color: #f6f8fa; font-weight: 600; }
  tr:nth-child(even) { background-color: #fbfcfd; }
  code { background: #f3f4f6; padding: 2px 5px; border-radius: 4px; font-family: Consolas, monospace; font-size: 12px; color: #cf222e; }
  
  /* Diagram Graphic Container */
  .diagram-box {
    background: #0f131a;
    border-radius: 8px;
    padding: 20px;
    margin: 20px 0;
    color: #fff;
    display: flex;
    justify-content: space-around;
    align-items: center;
    flex-wrap: wrap;
    gap: 15px;
  }
  .entity-card {
    background: #1c2230;
    border: 1px solid #7B6FFF;
    border-radius: 6px;
    width: 220px;
    overflow: hidden;
  }
  .entity-title {
    background: #7B6FFF;
    color: white;
    font-weight: bold;
    padding: 6px 12px;
    font-size: 13px;
    text-align: center;
  }
  .entity-fields {
    padding: 10px 12px;
    font-family: Consolas, monospace;
    font-size: 11.5px;
    color: #cbd5e1;
  }
  .entity-fields div {
    margin-bottom: 4px;
  }
  .field-pk { color: #f59e0b; font-weight: bold; }
  .relation-arrow {
    color: #7B6FFF;
    font-weight: bold;
    font-size: 20px;
  }
</style>
</head>
<body>

<div class="header">
  <h1>YOTRACKEZ — Database / Data Model (ER Diagram)</h1>
  <p style="margin: 4px 0 8px 0; color: #57606a;">Client-Side localStorage Data Architecture</p>
  <span class="badge">Live Web Schema</span>
</div>

<h2>1. Visual ER Diagram</h2>
<div class="diagram-box">
  <div class="entity-card">
    <div class="entity-title">userGoals</div>
    <div class="entity-fields">
      <div><span class="field-pk">PK</span> user_id: string</div>
      <div>dailyGoalCals: int</div>
      <div>dailyGoalProtein: int</div>
      <div>dailyGoalCarbs: int</div>
      <div>dailyGoalFat: int</div>
      <div>dailyGoalWater: int</div>
      <div>dailyGoalSteps: int</div>
    </div>
  </div>

  <div class="relation-arrow">&harr;</div>

  <div class="entity-card">
    <div class="entity-title">loggedMeals</div>
    <div class="entity-fields">
      <div><span class="field-pk">PK</span> id: timestamp</div>
      <div>food_name: string</div>
      <div>calories: float</div>
      <div>protein: float</div>
      <div>carbs: float</div>
      <div>fat: float</div>
      <div>fiber: float</div>
      <div>serving_size: string</div>
    </div>
  </div>

  <div class="relation-arrow">&harr;</div>

  <div class="entity-card">
    <div class="entity-title">avatarProgress</div>
    <div class="entity-fields">
      <div><span class="field-pk">PK</span> id: string</div>
      <div>xp: int</div>
      <div>level: int</div>
      <div>waterIntake: int</div>
      <div>steps: int</div>
    </div>
  </div>
</div>

<h2>2. Entity Details</h2>

<h3>A. <code>loggedMeals</code> (Array in localStorage)</h3>
<p>Stores every food item tracked by the user during daily logging.</p>
<table>
  <thead>
    <tr><th>Field</th><th>Type</th><th>Description</th></tr>
  </thead>
  <tbody>
    <tr><td><code>id</code></td><td>Number (Timestamp)</td><td>Unique identifier generated from timestamp</td></tr>
    <tr><td><code>food_name</code></td><td>String</td><td>Identified food title returned by Gemini</td></tr>
    <tr><td><code>calories</code></td><td>Float</td><td>Energy value in kcal</td></tr>
    <tr><td><code>protein</code></td><td>Float</td><td>Protein quantity in grams</td></tr>
    <tr><td><code>carbs</code></td><td>Float</td><td>Carbohydrates quantity in grams</td></tr>
    <tr><td><code>fat</code></td><td>Float</td><td>Total fat quantity in grams</td></tr>
    <tr><td><code>serving_size</code></td><td>String</td><td>Serving description (e.g., "1 bowl, 300g")</td></tr>
  </tbody>
</table>

<h3>B. <code>userGoals</code> (Object in localStorage)</h3>
<p>User-defined daily nutritional and wellness targets.</p>
<table>
  <thead>
    <tr><th>Field</th><th>Type</th><th>Default Value</th></tr>
  </thead>
  <tbody>
    <tr><td><code>dailyGoalCals</code></td><td>Integer</td><td>2200 kcal</td></tr>
    <tr><td><code>dailyGoalProtein</code></td><td>Integer</td><td>140 g</td></tr>
    <tr><td><code>dailyGoalCarbs</code></td><td>Integer</td><td>250 g</td></tr>
    <tr><td><code>dailyGoalFat</code></td><td>Integer</td><td>70 g</td></tr>
    <tr><td><code>dailyGoalWater</code></td><td>Integer</td><td>2500 ml</td></tr>
  </tbody>
</table>

</body>
</html>
"""

tech_doc_path = os.path.join(desktop, "YOTRACKEZ_Technical_Documentation.html")
er_doc_path = os.path.join(desktop, "YOTRACKEZ_ER_Diagram.html")

with open(tech_doc_path, "w", encoding="utf-8") as f:
    f.write(tech_doc_html)

with open(er_doc_path, "w", encoding="utf-8") as f:
    f.write(er_doc_html)

pdf_tech = os.path.join(desktop, "YOTRACKEZ_Technical_Documentation.pdf")
pdf_er = os.path.join(desktop, "YOTRACKEZ_ER_Diagram.pdf")

if os.path.exists(edge_path):
    subprocess.run([edge_path, "--headless", "--disable-gpu", f"--print-to-pdf={pdf_tech}", tech_doc_path], capture_output=True)
    subprocess.run([edge_path, "--headless", "--disable-gpu", f"--print-to-pdf={pdf_er}", er_doc_path], capture_output=True)
    print("PDF generation complete on Desktop!")
else:
    print("Edge not found at standard path.")
