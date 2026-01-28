
const { createClient } = require('@supabase/supabase-js');
const https = require('https');

// Configuration
const SUPABASE_URL = process.env.SUPABASE_URL || 'https://dnglcptmgjhoypsfoqaq.supabase.co';
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!SUPABASE_SERVICE_ROLE_KEY) {
    console.error("Error: Missing SUPABASE_SERVICE_ROLE_KEY env var.");
    process.exit(1);
}

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

function fetchLatestRates() {
    return new Promise((resolve, reject) => {
        const url = `https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/krw.json`;
        https.get(url, (res) => {
            if (res.statusCode !== 200) {
                resolve(null);
                return;
            }
            let data = '';
            res.on('data', (chunk) => data += chunk);
            res.on('end', () => {
                try {
                    const json = JSON.parse(data);
                    resolve(json['krw'] || null);
                } catch (e) {
                    resolve(null);
                }
            });
        }).on('error', (e) => resolve(null));
    });
}

async function main() {
    console.log("Updating latest FX rates...");
    const rates = await fetchLatestRates();

    if (!rates) {
        console.error("Failed to fetch rates.");
        return;
    }

    const upperRates = {};
    for (const [k, v] of Object.entries(rates)) {
        if (v !== 0) upperRates[k.toUpperCase()] = v;
    }

    const today = new Date().toISOString().split('T')[0];

    // 1. Update fx_latest_cache
    const { error: latestError } = await supabase.from('fx_latest_cache').upsert({
        base: 'KRW',
        rates: upperRates,
        last_updated_at: new Date().toISOString()
    });

    if (latestError) console.error("Latest update error:", latestError);
    else console.log("fx_latest_cache updated.");

    // 2. Update fx_history (today's entry)
    const { error: historyError } = await supabase.from('fx_history').upsert({
        date: today,
        base: 'KRW',
        rates: upperRates
    });

    if (historyError) console.error("History update error:", historyError);
    else console.log("fx_history (today) updated.");

    console.log("Done.");
}

main();
