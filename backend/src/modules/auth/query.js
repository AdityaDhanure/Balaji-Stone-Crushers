export const findUserByUsername = `
  SELECT * FROM users
  WHERE username = $1
  AND is_active = true
`;

export const updateLastLogin = `
  UPDATE users
  SET last_login = CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata',
      updated_at = CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata'
  WHERE username = $1
  RETURNING id, username, last_login
`;
