// src/routes/user-profile.routes.js
// Rute pentru profile publice și căutare utilizatori

const express = require('express');
const router = express.Router();
const userProfileController = require('../controllers/user-profile.controller');
const { optionalAuth } = require('../middleware/auth');

// ==========================================
// PUBLIC ROUTES (cu optional auth pentru personalizare)
// ==========================================

/**
 * @route   GET /api/v1/users/search
 * @desc    Search users by name
 * @access  Public
 */
router.get('/search', optionalAuth, userProfileController.searchUsers);

/**
 * @route   GET /api/v1/users/top-listers
 * @desc    Get top users with most pets listed
 * @access  Public
 */
router.get('/top-listers', optionalAuth, userProfileController.getTopListers);

/**
 * @route   GET /api/v1/users/:id/profile
 * @desc    Get public profile of a user
 * @access  Public
 */
router.get('/:id/profile', optionalAuth, userProfileController.getPublicProfile);

/**
 * @route   GET /api/v1/users/:id/pets
 * @desc    Get all pets of a user
 * @access  Public
 */
router.get('/:id/pets', optionalAuth, userProfileController.getUserPets);

module.exports = router;
