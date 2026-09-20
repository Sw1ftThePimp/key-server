const express = require('express');
const redis = require('redis');

const app = express();
app.use(express.json());

const PORT = process.env.PORT || 3000;

// Redis client — Render will auto-inject REDIS_URL from your Redis instance
const redisClient = redis.createClient({
    url: process.env.REDIS_URL
});

redisClient.on('error', (err) => console.error('Redis error:', err));

(async () => {
    await redisClient.connect();
    console.log('Connected to Redis');
})();

// ===== ENDPOINTS =====

// Health check
app.get('/', (req, res) => {
    res.json({ status: 'ok', service: 'key-server' });
});

// Validate key (POST /validate  body: { "key": "xxx" })
app.post('/validate', async (req, res) => {
    const { key } = req.body;

    if (!key || typeof key !== 'string') {
        return res.json({ valid: false, error: 'No key provided' });
    }

    try {
        // Check if key exists in Redis set called "valid_keys"
        const exists = await redisClient.sIsMember('valid_keys', key);

        if (exists) {
            // Optional: log usage
            await redisClient.hIncrBy('key_usage', key, 1);
            return res.json({ valid: true });
        } else {
            return res.json({ valid: false, error: 'Invalid key' });
        }
    } catch (err) {
        console.error('Validation error:', err);
        return res.json({ valid: false, error: 'Server error' });
    }
});

// Add key (POST /add  body: { "admin": "your-admin-password", "key": "new-key" })
app.post('/add', async (req, res) => {
    const { admin, key } = req.body;

    // Simple admin password check — change this!
    if (admin !== process.env.ADMIN_PASSWORD) {
        return res.json({ success: false, error: 'Unauthorized' });
    }

    if (!key) {
        return res.json({ success: false, error: 'No key provided' });
    }

    try {
        await redisClient.sAdd('valid_keys', key);
        return res.json({ success: true, message: 'Key added' });
    } catch (err) {
        return res.json({ success: false, error: 'Server error' });
    }
});

// Remove key (POST /remove  body: { "admin": "...", "key": "..." })
app.post('/remove', async (req, res) => {
    const { admin, key } = req.body;

    if (admin !== process.env.ADMIN_PASSWORD) {
        return res.json({ success: false, error: 'Unauthorized' });
    }

    try {
        await redisClient.sRem('valid_keys', key);
        return res.json({ success: true, message: 'Key removed' });
    } catch (err) {
        return res.json({ success: false, error: 'Server error' });
    }
});

// List all keys (POST /list  body: { "admin": "..." })
app.post('/list', async (req, res) => {
    const { admin } = req.body;

    if (admin !== process.env.ADMIN_PASSWORD) {
        return res.json({ success: false, error: 'Unauthorized' });
    }

    try {
        const keys = await redisClient.sMembers('valid_keys');
        return res.json({ success: true, keys });
    } catch (err) {
        return res.json({ success: false, error: 'Server error' });
    }
});

app.listen(PORT, () => {
    console.log(`Key server running on port ${PORT}`);
});
