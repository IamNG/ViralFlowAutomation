-- Add referral columns to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS referral_code TEXT UNIQUE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS referred_by UUID REFERENCES auth.users(id);

-- Function to allocate referral
CREATE OR REPLACE FUNCTION process_referral(new_user_id UUID, ref_code TEXT)
RETURNS void AS $$
DECLARE
  referrer_id UUID;
BEGIN
  -- Find the user with this referral code
  SELECT id INTO referrer_id FROM users WHERE referral_code = ref_code;
  
  IF referrer_id IS NOT NULL THEN
    -- Update the new user
    UPDATE users SET referred_by = referrer_id WHERE id = new_user_id;
    
    -- Give credits to the referrer
    UPDATE users SET credits_remaining = credits_remaining + 50 WHERE id = referrer_id;
    
    -- Give credits to the new user
    UPDATE users SET credits_remaining = credits_remaining + 50 WHERE id = new_user_id;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
