require('dotenv').config();
const express = require('express');
const cors = require('cors');
const rateLimit = require('express-rate-limit');
const jwt = require('jsonwebtoken');
const { GoogleGenerativeAI } = require('@google/generative-ai');

const app = express();
app.use(express.json());
app.use(cors());

// --- SECURITY PROTOCOLS ---

// 1. Rate Limiting (Prevent Bot Exhaustion)
const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 50, // Limit each IP to 50 requests per `window`
  message: { error: 'Rate limit exceeded. Please try again later.' },
  standardHeaders: true,
  legacyHeaders: false,
});
app.use('/api/', apiLimiter);

// 2. Secret App Token Verification & Rapid JWT Issue
const APP_SECRET_XOR_MATCH = process.env.APP_SECRET_TOKEN || "nebula_edge_token_123";
const JWT_SECRET = process.env.JWT_SECRET || "super_secret_jwt_nebula_signing_key";

app.post('/api/v1/auth', (req, res) => {
  const { clientSecret, timestamp } = req.body;
  // Anti-replay: timestamp must be within 60 seconds of server time
  const now = Date.now();
  if (Math.abs(now - parseInt(timestamp)) > 60000) {
    return res.status(401).json({ error: 'Auth failed: Token Expired or Replay Detected' });
  }

  if (clientSecret === APP_SECRET_XOR_MATCH) {
    // Issue a 5-minute cryptographic JWT
    const token = jwt.sign({ device: 'nebula_edge_client' }, JWT_SECRET, { expiresIn: '5m' });
    return res.json({ token });
  }
  return res.status(403).json({ error: 'Forbidden: Invalid Hardware Signature' });
});

const verifyJWT = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Unauthorized: Missing JWT' });
  }
  const token = authHeader.split(' ')[1];
  
  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) return res.status(403).json({ error: 'Forbidden: JWT Expired or Corrupted' });
    req.user = user;
    next();
  });
};

// --- GEMINI PROXY ---

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

app.post('/api/v1/gemini', verifyJWT, async (req, res) => {
  const { query, history } = req.body;
  
  // Strict API Sanitization
  if (!query || typeof query !== 'string' || query.trim().length === 0) {
    return res.status(400).json({ error: 'Invalid input. Query must not be empty.' });
  }
  if (query.length > 500) {
      return res.status(400).json({ error: 'Payload too large. Maximum 500 characters allowed for Edge compute.' });
  }

  try {
    const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });
    
    // Server-Side System Prompt Envelope (Prevents Injection & Hardware Command Spillage)
    const prompt = `You are Nebula, a highly-intelligent smart habitat IoT AI assistant. 
Keep your responses futuristic and concise.
CRITICAL: Do absolutely NOT return physical hardware commands like [COMMAND:RELAY_1:ON]. Leave that to local hardware logic.
Respond cleanly to this user input:
User: ${query}`;

    // Secure Timeout Protection utilizing AbortController
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 4000);

    const result = await model.generateContent(prompt, { signal: controller.signal });
    clearTimeout(timeoutId);

    const response = await result.response;
    let text = response.text().trim();
    
    // Final Hardware Sanitation Strip
    text = text.replace(/\[COMMAND:.*?\]/g, "");

    res.status(200).json({ answer: text + " ☁️" });
  } catch (error) {
    if (error.name === 'AbortError') {
      console.warn("Gemini Cloud API Timeout Aborted!");
      return res.status(504).json({ error: 'Upstream Model Timeout' });
    }
    console.error("Gemini API Error:", error);
    res.status(500).json({ error: 'Internal Cloud Error. The model proxy failed.' });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`[NEBULA] Secure AI Proxy running on port ${PORT}`);
});
