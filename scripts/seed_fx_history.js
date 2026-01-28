
const { createClient } = require('@supabase/supabase-js');
const https = require('https');

// Configuration - Load from process.env (or set manually if testing quickly)
// When running via `npx supabase`, these might be exposed or we can source .env
const SUPABASE_URL = process.env.SUPABASE_URL || 'http://127.0.0.1:54321';
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!SUPABASE_SERVICE_ROLE_KEY) {
    console.error("Error: Missing SUPABASE_SERVICE_ROLE_KEY env var.");
    console.error("Usage: SUPABASE_SERVICE_ROLE_KEY=... node scripts/seed_fx_history.js");
    process.exit(1);
}

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

// Helper: Generate dates for the last 365 days
function getPastDates(days) {
    const dates = [];
    const today = new Date();
    for (let i = 1; i <= days; i++) { // Start from yesterday
        const d = new Date(today);
        d.setDate(today.getDate() - i);
        dates.push(d.toISOString().split('T')[0]); // YYYY-MM-DD
    }
    return dates;
}

// Fetch rates for a specific date (Node.js native https)
function fetchRatesForDate(date) {
    return new Promise((resolve, reject) => {
        const url = `https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@${date}/v1/currencies/krw.json`;
        https.get(url, (res) => {
            if (res.statusCode !== 200) {
                console.warn(`[${date}] Failed to fetch: Status ${res.statusCode}`);
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
                    console.error(`[${date}] JSON Parse Error: ${e.message}`);
                    resolve(null);
                }
            });
        }).on('error', (e) => {
            console.error(`[${date}] Request Error: ${e.message}`);
            resolve(null);
        });
    });
}

async function main() {
    console.log("Starting FX history seeding (Node.js)...");

    const dates = getPastDates(365); // 1 Year
    console.log(`Target: ${dates.length} days (From ${dates[0]} to ${dates[dates.length - 1]})`);

    const CHUNK_SIZE = 5;

    for (let i = 0; i < dates.length; i += CHUNK_SIZE) {
        const chunkDates = dates.slice(i, i + CHUNK_SIZE);
        const dbRows = [];

        await Promise.all(chunkDates.map(async (date) => {
            const rates = await fetchRatesForDate(date);
            if (rates) {
                const upperRates = {};
                for (const [k, v] of Object.entries(rates)) {
                    if (v !== 0) upperRates[k.toUpperCase()] = v;
                }

                dbRows.push({
                    date: date,
                    base: 'KRW',
                    rates: upperRates,
                });
                console.log(`[${date}] Fetched.`);
            }
        }));

        if (dbRows.length > 0) {
            const { error } = await supabase.from('fx_history').upsert(dbRows);
            if (error) {
                console.error('DB Upsert Error:', error);
            } else {
                console.log(`Saved ${dbRows.length} rows to DB.`);
            }
        }

        // Delay
        await new Promise(r => setTimeout(r, 500));
    }

    console.log("Seeding complete.");
}

main();
