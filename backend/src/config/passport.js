// src/config/passport.js
const passport = require('passport');
const GoogleStrategy = require('passport-google-oauth20').Strategy;
const FacebookStrategy = require('passport-facebook').Strategy;
const AppleStrategy = require('passport-apple').Strategy;
const { query } = require('./database');
require('dotenv').config();

// Serialize user for session
passport.serializeUser((user, done) => {
  done(null, user.id);
});

// Deserialize user from session
passport.deserializeUser(async (id, done) => {
  try {
    const result = await query(
      'SELECT id, email, name, avatar_url, is_verified, is_admin FROM users WHERE id = $1 AND deleted_at IS NULL',
      [id]
    );
    done(null, result.rows[0]);
  } catch (error) {
    done(error, null);
  }
});

// ==========================================
// GOOGLE OAUTH STRATEGY
// ==========================================
if (process.env.GOOGLE_CLIENT_ID && process.env.GOOGLE_CLIENT_SECRET) {
  passport.use(
    new GoogleStrategy(
      {
        clientID: process.env.GOOGLE_CLIENT_ID,
        clientSecret: process.env.GOOGLE_CLIENT_SECRET,
        callbackURL: process.env.GOOGLE_CALLBACK_URL,
        scope: ['profile', 'email'],
      },
      async (accessToken, refreshToken, profile, done) => {
        try {
          const email = profile.emails[0].value;
          const name = profile.displayName;
          const avatar_url = profile.photos[0]?.value || null;

          // Check if user exists
          let result = await query(
            'SELECT * FROM users WHERE email = $1 AND deleted_at IS NULL',
            [email]
          );

          let user;
          if (result.rows.length > 0) {
            // User exists - update last login
            user = result.rows[0];
            await query(
              'UPDATE users SET last_login = CURRENT_TIMESTAMP WHERE id = $1',
              [user.id]
            );
          } else {
            // Check if this is the first user (should be admin)
            const countResult = await query(
              'SELECT COUNT(*) FROM users WHERE is_admin = true'
            );
            const isFirstAdmin = parseInt(countResult.rows[0].count) === 0;

            // Create new user - OAuth users are auto-verified
            result = await query(
              `INSERT INTO users (email, name, avatar_url, is_verified, is_admin, password, last_login) 
               VALUES ($1, $2, $3, true, $4, 'oauth_google', CURRENT_TIMESTAMP) 
               RETURNING *`,
              [email, name, avatar_url, isFirstAdmin]
            );
            user = result.rows[0];
          }

          return done(null, user);
        } catch (error) {
          return done(error, null);
        }
      }
    )
  );
}

// ==========================================
// FACEBOOK OAUTH STRATEGY
// ==========================================
if (process.env.FACEBOOK_APP_ID && process.env.FACEBOOK_APP_SECRET) {
  passport.use(
    new FacebookStrategy(
      {
        clientID: process.env.FACEBOOK_APP_ID,
        clientSecret: process.env.FACEBOOK_APP_SECRET,
        callbackURL: process.env.FACEBOOK_CALLBACK_URL,
        profileFields: ['id', 'emails', 'name', 'picture.type(large)'],
      },
      async (accessToken, refreshToken, profile, done) => {
        try {
          const email = profile.emails[0].value;
          const name = `${profile.name.givenName} ${profile.name.familyName}`;
          const avatar_url = profile.photos[0]?.value || null;

          // Check if user exists
          let result = await query(
            'SELECT * FROM users WHERE email = $1 AND deleted_at IS NULL',
            [email]
          );

          let user;
          if (result.rows.length > 0) {
            // User exists - update last login
            user = result.rows[0];
            await query(
              'UPDATE users SET last_login = CURRENT_TIMESTAMP WHERE id = $1',
              [user.id]
            );
          } else {
            // Check if this is the first user (should be admin)
            const countResult = await query(
              'SELECT COUNT(*) FROM users WHERE is_admin = true'
            );
            const isFirstAdmin = parseInt(countResult.rows[0].count) === 0;

            // Create new user - OAuth users are auto-verified
            result = await query(
              `INSERT INTO users (email, name, avatar_url, is_verified, is_admin, password, last_login) 
               VALUES ($1, $2, $3, true, $4, 'oauth_facebook', CURRENT_TIMESTAMP) 
               RETURNING *`,
              [email, name, avatar_url, isFirstAdmin]
            );
            user = result.rows[0];
          }

          return done(null, user);
        } catch (error) {
          return done(error, null);
        }
      }
    )
  );
}

// ==========================================
// APPLE OAUTH STRATEGY
// ==========================================
if (
  process.env.APPLE_CLIENT_ID &&
  process.env.APPLE_TEAM_ID &&
  process.env.APPLE_KEY_ID &&
  process.env.APPLE_PRIVATE_KEY_PATH
) {
  const fs = require('fs');
  const path = require('path');

  passport.use(
    new AppleStrategy(
      {
        clientID: process.env.APPLE_CLIENT_ID,
        teamID: process.env.APPLE_TEAM_ID,
        keyID: process.env.APPLE_KEY_ID,
        privateKeyLocation: path.resolve(process.env.APPLE_PRIVATE_KEY_PATH),
        callbackURL: process.env.APPLE_CALLBACK_URL,
        scope: ['name', 'email'],
      },
      async (accessToken, refreshToken, idToken, profile, done) => {
        try {
          // Apple provides minimal profile information
          const email = profile.email;
          const name = profile.name
            ? `${profile.name.firstName} ${profile.name.lastName}`
            : 'Apple User';

          // Check if user exists
          let result = await query(
            'SELECT * FROM users WHERE email = $1 AND deleted_at IS NULL',
            [email]
          );

          let user;
          if (result.rows.length > 0) {
            // User exists - update last login
            user = result.rows[0];
            await query(
              'UPDATE users SET last_login = CURRENT_TIMESTAMP WHERE id = $1',
              [user.id]
            );
          } else {
            // Check if this is the first user (should be admin)
            const countResult = await query(
              'SELECT COUNT(*) FROM users WHERE is_admin = true'
            );
            const isFirstAdmin = parseInt(countResult.rows[0].count) === 0;

            // Create new user - OAuth users are auto-verified
            result = await query(
              `INSERT INTO users (email, name, is_verified, is_admin, password, last_login) 
               VALUES ($1, $2, true, $3, 'oauth_apple', CURRENT_TIMESTAMP) 
               RETURNING *`,
              [email, name, isFirstAdmin]
            );
            user = result.rows[0];
          }

          return done(null, user);
        } catch (error) {
          return done(error, null);
        }
      }
    )
  );
}

module.exports = passport;