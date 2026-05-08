from flask import Flask, jsonify, render_template_string
import os

app = Flask(__name__)

HTML_TEMPLATE = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Flask CI/CD App</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', sans-serif;
            background: #0f172a;
            color: #e2e8f0;
            display: flex;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
        }
        .card {
            background: #1e293b;
            border: 1px solid #334155;
            border-radius: 12px;
            padding: 40px;
            text-align: center;
            max-width: 500px;
            width: 90%;
        }
        h1 { color: #38bdf8; font-size: 2rem; margin-bottom: 10px; }
        p { color: #94a3b8; margin: 8px 0; }
        .badge {
            display: inline-block;
            background: #065f46;
            color: #6ee7b7;
            padding: 4px 12px;
            border-radius: 999px;
            font-size: 0.8rem;
            margin-top: 16px;
        }
        .env { color: #fbbf24; font-weight: 600; }
    </style>
</head>
<body>
    <div class="card">
        <h1>🚀 Flask CI/CD App</h1>
        <p>Deployed via <strong>GitHub Actions</strong> + <strong>Docker</strong></p>
        <p>Running on: <span class="env">{{ env }}</span></p>
        <p>Version: <span class="env">{{ version }}</span></p>
        <div class="badge">✓ Pipeline Healthy</div>
    </div>
</body>
</html>
"""

@app.route("/")
def index():
    return render_template_string(
        HTML_TEMPLATE,
        env=os.getenv("FLASK_ENV", "production"),
        version=os.getenv("APP_VERSION", "1.0.0")
    )

@app.route("/health")
def health():
    return jsonify({"status": "healthy", "version": os.getenv("APP_VERSION", "1.0.0")}), 200

@app.route("/api/info")
def info():
    return jsonify({
        "app": "Flask CI/CD Demo",
        "environment": os.getenv("FLASK_ENV", "production"),
        "version": os.getenv("APP_VERSION", "1.0.0")
    })

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=os.getenv("FLASK_ENV") == "development")
