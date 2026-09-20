const express = require('express');
const redis = require('redis');

const app = express();
app.use(express.json());

const PORT = process.env.PORT || 3000;

const redisClient = redis.createClient({
    url: process.env.REDIS_URL
});

redisClient.on('error', (err) => console.error('Redis error:', err));

(async () => {
    await redisClient.connect();
    console.log('Connected to Redis');
})();

// ===== ENDPOINTS =====

app.get('/', (req, res) => {
    res.json({ status: 'ok', service: 'key-server' });
});

// Validate key + HWID
// POST /validate  body: { "key": "...", "hwid": "..." }
app.post('/validate', async (req, res) => {
    const { key, hwid } = req.body;

    if (!key || typeof key !== 'string') {
        return res.json({ valid: false, error: 'No key provided' });
    }
    if (!hwid || typeof hwid !== 'string') {
        return res.json({ valid: false, error: 'No HWID provided' });
    }

    try {
        // 1. Check if key exists
        const exists = await redisClient.sIsMember('valid_keys', key);
        if (!exists) {
            return res.json({ valid: false, error: 'Invalid key' });
        }

        // 2. Check if key is already bound to an HWID
        const boundHwid = await redisClient.hGet('key_bindings', key);

        if (!boundHwid) {
            // Never used → bind to this HWID
            await redisClient.hSet('key_bindings', key, hwid);
            await redisClient.hSet('key_last_used', key, Date.now().toString());
            await redisClient.hIncrBy('key_usage', key, 1);
            return res.json({ valid: true, message: 'Key bound to this PC' });
        }

        if (boundHwid === hwid) {
            // Same HWID → OK
            await redisClient.hSet('key_last_used', key, Date.now().toString());
            await redisClient.hIncrBy('key_usage', key, 1);
            return res.json({ valid: true });
        }

        // Bound to different HWID → reject
        return res.json({
            valid: false,
            error: 'Key is already bound to another PC. Contact admin to reset.'
        });

    } catch (err) {
        console.error('Validation error:', err);
        return res.json({ valid: false, error: 'Server error' });
    }
});

// Add key (admin)
// POST /add  body: { "admin": "...", "key": "..." }
app.post('/add', async (req, res) => {
    const { admin, key } = req.body;
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

// Remove key (admin)
// POST /remove  body: { "admin": "...", "key": "..." }
app.post('/remove', async (req, res) => {
    const { admin, key } = req.body;
    if (admin !== process.env.ADMIN_PASSWORD) {
        return res.json({ success: false, error: 'Unauthorized' });
    }
    try {
        await redisClient.sRem('valid_keys', key);
        await redisClient.hDel('key_bindings', key);
        await redisClient.hDel('key_usage', key);
        await redisClient.hDel('key_last_used', key);
        return res.json({ success: true, message: 'Key removed' });
    } catch (err) {
        return res.json({ success: false, error: 'Server error' });
    }
});

// Reset a key's HWID binding (admin)
// POST /reset  body: { "admin": "...", "key": "..." }
app.post('/reset', async (req, res) => {
    const { admin, key } = req.body;
    if (admin !== process.env.ADMIN_PASSWORD) {
        return res.json({ success: false, error: 'Unauthorized' });
    }
    if (!key) {
        return res.json({ success: false, error: 'No key provided' });
    }
    try {
        await redisClient.hDel('key_bindings', key);
        return res.json({ success: true, message: 'HWID binding cleared — key can be used on a new PC' });
    } catch (err) {
        return res.json({ success: false, error: 'Server error' });
    }
});

// List all keys + their HWID bindings (admin)
// POST /list  body: { "admin": "..." }
app.post('/list', async (req, res) => {
    const { admin } = req.body;
    if (admin !== process.env.ADMIN_PASSWORD) {
        return res.json({ success: false, error: 'Unauthorized' });
    }
    try {
        const keys = await redisClient.sMembers('valid_keys');
        const bindings = await redisClient.hGetAll('key_bindings');
        const usage = await redisClient.hGetAll('key_usage');
        const result = keys.map(k => ({
            key: k,
            hwid: bindings[k] || null,
            uses: usage[k] || '0'
        }));
        return res.json({ success: true, keys: result });
    } catch (err) {
        return res.json({ success: false, error: 'Server error' });
    }
});

app.listen(PORT, () => {
    console.log(`Key server running on port ${PORT}`);
});
