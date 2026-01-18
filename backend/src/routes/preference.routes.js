// src/routes/preference.routes.js
const express = require('express');
const router = express.Router();
const preferenceController = require('../controllers/preference.controller');
const { authenticate } = require('../middleware/auth');
const { validatePreferences } = require('../validators/preference.validators');

// ==========================================
// ALL ROUTES REQUIRE AUTHENTICATION
// ==========================================

/**
 * @route   GET /api/v1/preferences
 * @desc    Get user's preferences
 * @access  Private
 */
router.get('/', authenticate, preferenceController.getPreferences);

/**
 * @route   POST /api/v1/preferences
 * @desc    Create/save user preferences (from onboarding)
 * @access  Private
 */
router.post(
  '/',
  authenticate,
  validatePreferences,
  preferenceController.createPreferences
);

/**
 * @route   PUT /api/v1/preferences
 * @desc    Update user preferences
 * @access  Private
 */
router.put(
  '/',
  authenticate,
  validatePreferences,
  preferenceController.updatePreferences
);

/**
 * @route   DELETE /api/v1/preferences
 * @desc    Delete user preferences
 * @access  Private
 */
router.delete('/', authenticate, preferenceController.deletePreferences);

module.exports = router;
