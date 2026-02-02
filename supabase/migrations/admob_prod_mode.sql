-- [AdMob Production Mode] Apply real production IDs for release
INSERT INTO public.app_settings (setting_key, setting_value, description)
VALUES 
  ('admob_banner_ids', '{
    "android": "ca-app-pub-8142649369272916/3942632207",
    "ios": "ca-app-pub-8142649369272916/3942632207"
  }'::jsonb, 'Production Ad Unit IDs for Banner'),
  ('admob_interstitial_ids', '{
    "android": "ca-app-pub-8142649369272916/9641681447",
    "ios": "ca-app-pub-8142649369272916/9641681447"
  }'::jsonb, 'Production Ad Unit IDs for Interstitial')
ON CONFLICT (setting_key) 
DO UPDATE SET setting_value = EXCLUDED.setting_value;
