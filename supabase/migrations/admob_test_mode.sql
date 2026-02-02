-- [AdMob Test Mode] Apply official Google Test IDs for development
INSERT INTO public.app_settings (setting_key, setting_value, description)
VALUES 
  ('admob_banner_ids', '{
    "android": "ca-app-pub-3940256099942544/6300978111",
    "ios": "ca-app-pub-3940256099942544/2934735716"
  }'::jsonb, 'Test Ad Unit IDs for Banner'),
  ('admob_interstitial_ids', '{
    "android": "ca-app-pub-3940256099942544/1033173712",
    "ios": "ca-app-pub-3940256099942544/4411468910"
  }'::jsonb, 'Test Ad Unit IDs for Interstitial')
ON CONFLICT (setting_key) 
DO UPDATE SET setting_value = EXCLUDED.setting_value;
