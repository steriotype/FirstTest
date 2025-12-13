Login demo
This is not me
This is a simple static login page demo. It provides:

- Username/password form with client-side validation
- "Forgot password" modal that simulates sending a reset email
- "Sign in with Google" button (placeholder; no real OAuth)

How to run locally

1. Open a terminal in this folder: `C:\Users\ianma\IdeaProjects\FirstTest\web`
2. Start a simple HTTP server (Python 3):

```powershell
python -m http.server 8000;
```

3. Open http://localhost:8000/ in your browser.

Notes

- Real Google Sign-In requires a Client ID and server-side token exchange; this demo only simulates the flow.

