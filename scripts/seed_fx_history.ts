
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { format } from "https://deno.land/std@0.168.0/datetime/mod.ts";

// Configuration
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
    console.error("Error: Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY env vars.");
    Deno.exit(1);
}

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

// Helper: Generate dates for the last 365 days
function getPastDates(days: number): string[] {
    const dates = [];
    const today = new Date();
    for (let i = 1; i <= days; i++) { // Start from yesterday
        const d = new Date(today);
        d.setDate(today.getDate() - i);
        dates.push(d.toISOString().split('T')[0]); // YYYY-MM-DD
    }
    return dates;
}

// Fetch rates for a specific date
async function fetchRatesForDate(date: string): Promise<Record<string, number> | null> {
    const url = `https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@${date}/v1/currencies/krw.json`;
    try {
        const res = await fetch(url);
        if (!res.ok) {
            // 404 or other error means data might not be available for that specific date (or future date)
            console.warn(`[${date}] Failed to fetch: ${res.statusText}`);
            return null;
        }
        const data = await res.json();
        return data['krw'] || null;
    } catch (e) {
        console.error(`[${date}] Error fetching: ${e.message}`);
        return null;
    }
}

async function main() {
    console.log("Starting FX history seeding...");

    const dates = getPastDates(365); // 1 Year
    console.log(`Target: ${dates.length} days (From ${dates[0]} to ${dates[dates.length - 1]})`);

    // Process in chunks to avoid overwhelming API or DB
    const CHUNK_SIZE = 5;

    for (let i = 0; i < dates.length; i += CHUNK_SIZE) {
        const chunkDates = dates.slice(i, i + CHUNK_SIZE);
        const dbRows: any[] = [];

        await Promise.all(chunkDates.map(async (date) => {
            const rates = await fetchRatesForDate(date);
            if (rates) {
                // Convert to uppercase keys
                const upperRates: Record<string, number> = {};
                for (const [k, v] of Object.entries(rates)) {
                    if (v !== 0) upperRates[k.toUpperCase()] = v as number;
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

        // Polite delay
        await new Promise(r => setTimeout(r, 500));
    }

    console.log("Seeding complete.");
}

main();
