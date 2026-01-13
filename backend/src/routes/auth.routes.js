// src/routes/auth.routes.js
const express = require('express');
const router = express.Router();
const authController = require('../controllers/auth.controller');
const oauthController = require('../controllers/oauth.controller');
const { authenticate, requireVerified } = require('../middleware/auth');
const {
  validateRegister,
  validateAdminRegister,
  validateLogin,
  validateForgotPassword,
  validateResetPassword,
  validateChangePassword,
  validateVerifyEmail,
  validateRefreshToken,
  validateMFAToken,
  validateUpdateProfile,
} = require('../validators/auth.validators');
const passport = require('../config/passport');

// ==========================================
// PUBLIC ROUTES (NO AUTHENTICATION REQUIRED)
// ==========================================

/**
 * @route   POST /api/v1/auth/register
 * @desc    Register new user
 * @access  Public
 */
router.post('/register', validateRegister, authController.register);

/**
 * @route   POST /api/v1/auth/admin/register
 * @desc    Register new admin (requires secret key)
 * @access  Public (but requires ADMIN_SECRET_KEY)
 */
router.post(
  '/admin/register',
  validateAdminRegister,
  authController.registerAdmin
);

/**
 * @route   POST /api/v1/auth/login
 * @desc    Login user
 * @access  Public
 */
router.post('/login', validateLogin, authController.login);

/**
 * @route   POST /api/v1/auth/verify-email
 * @desc    Verify email with token
 * @access  Public
 */
router.post('/verify-email', validateVerifyEmail, authController.verifyEmail);

/**
 * @route   POST /api/v1/auth/resend-verification
 * @desc    Resend verification email
 * @access  Public
 */
router.post(
  '/resend-verification',
  validateForgotPassword,
  authController.resendVerification
);

/**
 * @route   POST /api/v1/auth/forgot-password
 * @desc    Request password reset
 * @access  Public
 */
router.post(
  '/forgot-password',
  validateForgotPassword,
  authController.forgotPassword
);

/**
 * @route   POST /api/v1/auth/reset-password
 * @desc    Reset password with token
 * @access  Public
 */
router.post(
  '/reset-password',
  validateResetPassword,
  authController.resetPassword
);

/**
 * @route   POST /api/v1/auth/refresh-token
 * @desc    Refresh access token
 * @access  Public
 */
router.post(
  '/refresh-token',
  validateRefreshToken,
  authController.refreshToken
);

/**
 * @route   POST /api/v1/auth/mfa/login
 * @desc    Login with MFA
 * @access  Public
 */
router.post('/mfa/login', validateMFAToken, authController.loginWithMFA);

// ==========================================
// OAUTH ROUTES
// ==========================================

/**
 * @route   GET /api/v1/auth/google
 * @desc    Start Google OAuth flow
 * @access  Public
 */
router.get(
  '/google',
  passport.authenticate('google', { scope: ['profile', 'email'] })
);

/**
 * @route   GET /api/v1/auth/google/callback
 * @desc    Google OAuth callback
 * @access  Public
 */
router.get(
  '/google/callback',
  passport.authenticate('google', { 
    failureRedirect: `${process.env.FRONTEND_URL}/login?error=google_auth_failed`,
    session: false 
  }),
  oauthController.googleCallback
);

/**
 * @route   GET /api/v1/auth/facebook
 * @desc    Start Facebook OAuth flow
 * @access  Public
 */
router.get(
  '/facebook',
  passport.authenticate('facebook', { scope: ['email'] })
);

/**
 * @route   GET /api/v1/auth/facebook/callback
 * @desc    Facebook OAuth callback
 * @access  Public
 */
router.get(
  '/facebook/callback',
  passport.authenticate('facebook', { 
    failureRedirect: `${process.env.FRONTEND_URL}/login?error=facebook_auth_failed`,
    session: false 
  }),
  oauthController.facebookCallback
);

/**
 * @route   GET /api/v1/auth/apple
 * @desc    Start Apple OAuth flow
 * @access  Public
 */
router.get(
  '/apple',
  passport.authenticate('apple', { scope: ['name', 'email'] })
);

/**
 * @route   GET /api/v1/auth/apple/callback
 * @desc    Apple OAuth callback
 * @access  Public
 */
router.post(
  '/apple/callback',
  passport.authenticate('apple', { 
    failureRedirect: `${process.env.FRONTEND_URL}/login?error=apple_auth_failed`,
    session: false 
  }),
  oauthController.appleCallback
);

// ==========================================
// PROTECTED ROUTES (AUTHENTICATION REQUIRED)
// ==========================================

/**
 * @route   GET /api/v1/auth/me
 * @desc    Get current user profile
 * @access  Private
 */
router.get('/me', authenticate, authController.getCurrentUser);

/**
 * @route   PUT /api/v1/auth/profile
 * @desc    Update user profile
 * @access  Private
 */
router.put(
  '/profile',
  authenticate,
  validateUpdateProfile,
  authController.updateProfile
);

/**
 * @route   POST /api/v1/auth/change-password
 * @desc    Change password
 * @access  Private
 */
router.post(
  '/change-password',
  authenticate,
  validateChangePassword,
  authController.changePassword
);

/**
 * @route   POST /api/v1/auth/mfa/setup
 * @desc    Setup MFA (Google Authenticator)
 * @access  Private + Verified
 */
router.post(
  '/mfa/setup',
  authenticate,
  requireVerified,
  authController.setupMFA
);

/**
 * @route   POST /api/v1/auth/mfa/verify
 * @desc    Verify and enable MFA
 * @access  Private + Verified
 */
router.post(
  '/mfa/verify',
  authenticate,
  requireVerified,
  validateMFAToken,
  authController.verifyMFA
);

/**
 * @route   DELETE /api/v1/auth/mfa/disable
 * @desc    Disable MFA
 * @access  Private + Verified
 */
router.delete(
  '/mfa/disable',
  authenticate,
  requireVerified,
  authController.disableMFA
);

module.exports = router;