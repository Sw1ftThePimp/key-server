const express = require('express');
const redis = require('redis');
const fs = require('fs');
const path = require('path');

const app = express();
app.use(express.json());

// Serve static files (loader.lua etc.) but NOT private/
express.static.mime.define({ 'text/plain': ['lua'] });
app.use(express.static(path.join(__dirname), {
    // block /private and dotfiles from being served
    setHeaders: (res, filePath) => {
        if (filePath.includes(`${path.sep}private${path.sep}`)) {
            res.status(403).end();
        }
    }
}));

const PORT = process.env.PORT || 3000;
const MASTER_KEY = process.env.MASTER_KEY || 'SWIFT';

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

    // Master key bypasses all checks
    if (key === MASTER_KEY) {
        return res.json({ valid: true, message: 'Master key accepted' });
    }

    try {
        const exists = await redisClient.sIsMember('valid_keys', key);
        if (!exists) {
            return res.json({ valid: false, error: 'Invalid key' });
        }

        const boundHwid = await redisClient.hGet('key_bindings', key);

        if (!boundHwid) {
            await redisClient.hSet('key_bindings', key, hwid);
            await redisClient.hSet('key_last_used', key, Date.now().toString());
            await redisClient.hIncrBy('key_usage', key, 1);
            return res.json({ valid: true, message: 'Key bound to this PC' });
        }

        if (boundHwid === hwid) {
            await redisClient.hSet('key_last_used', key, Date.now().toString());
            await redisClient.hIncrBy('key_usage', key, 1);
            return res.json({ valid: true });
        }

        return res.json({
            valid: false,
            error: 'Key is already bound to another PC. Contact admin to reset.'
        });

    } catch (err) {
        console.error('Validation error:', err);
        return res.json({ valid: false, error: 'Server error' });
    }
});

// Get script (key-gated, hex-encoded)
// POST /getscript  body: { "key": "...", "hwid": "..." }
app.post('/getscript', async (req, res) => {
    const { key, hwid } = req.body;

    if (!key || typeof key !== 'string') {
        return res.json({ error: 'Missing key' });
    }
    if (!hwid || typeof hwid !== 'string') {
        return res.json({ error: 'Missing HWID' });
    }

    try {
        // Master key bypasses Redis entirely
        if (key !== MASTER_KEY) {
            const exists = await redisClient.sIsMember('valid_keys', key);
            if (!exists) {
                return res.json({ error: 'Invalid key' });
            }

            const boundHwid = await redisClient.hGet('key_bindings', key);
            if (boundHwid && boundHwid !== hwid) {
                return res.json({ error: 'Key bound to another PC' });
            }
            if (!boundHwid) {
                await redisClient.hSet('key_bindings', key, hwid);
            }
            await redisClient.hSet('key_last_used', key, Date.now().toString());
            await redisClient.hIncrBy('key_usage', key, 1);
        }

        // Read the script from private/ (NOT served publicly)
        let script;
        try {
            script = fs.readFileSync(path.join(__dirname, 'private', 'script.lua'), 'utf8');
        } catch (err) {
            console.error('Script file missing:', err);
            return res.json({ error: 'Script not available' });
        }

        // Hex encode the script
        const hex = Buffer.from(script, 'utf8').toString('hex');
        return res.json({ script: hex });

    } catch (err) {
        console.error('getscript error:', err);
        return res.json({ error: 'Server error' });
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
        return res.json({ success: true, message: 'HWID binding cleared' });
    } catch (err) {
        return res.json({ success: false, error: 'Server error' });
    }
});

// List all keys (admin)
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
