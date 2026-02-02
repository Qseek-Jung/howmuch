-- Create app_settings table for remote configuration
CREATE TABLE IF NOT EXISTS public.app_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  setting_key TEXT UNIQUE NOT NULL,
  setting_value JSONB NOT NULL,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS
ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;

-- Create policy to allow public read access
CREATE POLICY "Allow public read access" ON public.app_settings
  FOR SELECT
  USING (true);

-- Create policy to allow only authenticated users to modify (for admin control)
CREATE POLICY "Allow authenticated users to update" ON public.app_settings
  FOR ALL
  USING (auth.uid() IS NOT NULL);

-- Insert default settings
INSERT INTO public.app_settings (setting_key, setting_value, description)
VALUES 
  ('ads_enabled', '{"enabled": true}'::jsonb, 'Global ad control for testing - set to false to disable all ads'),
  ('app_version_min', '{"version": "1.0.0"}'::jsonb, 'Minimum required app version'),
  ('force_update', '{"required": false}'::jsonb, 'Force app update flag')
ON CONFLICT (setting_key) DO NOTHING;

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_app_settings_updated_at
    BEFORE UPDATE ON public.app_settings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
