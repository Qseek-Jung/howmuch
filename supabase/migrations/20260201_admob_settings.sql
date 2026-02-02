-- Add AdMob Interstitial Unit IDs to app_settings
INSERT INTO public.app_settings (setting_key, setting_value, description)
VALUES 
  ('admob_interstitial_ids', '{
    "android": "ca-app-pub-3940256099942544/1033173712",
    "ios": "ca-app-pub-3940256099942544/4411468910"
  }'::jsonb, 'AdMob Interstitial Ad Unit IDs for each platform (default to test IDs)')
ON CONFLICT (setting_key) 
DO UPDATE SET setting_value = EXCLUDED.setting_value;
