// src/routes/favorite.routes.js
const express = require('express');
const router = express.Router();
const favoriteController = require('../controllers/favorite.controller');
const { authenticate } = require('../middleware/auth');

// ==========================================
// ALL ROUTES REQUIRE AUTHENTICATION
// ==========================================

/**
 * @route   GET /api/v1/favorites
 * @desc    Get user's favorite pets
 * @access  Private
 */
router.get('/', authenticate, favoriteController.getFavorites);

/**
 * @route   GET /api/v1/favorites/:petId/check
 * @desc    Check if a pet is in user's favorites
 * @access  Private
 */
router.get('/:petId/check', authenticate, favoriteController.checkFavorite);

/**
 * @route   POST /api/v1/favorites/:petId
 * @desc    Add pet to favorites
 * @access  Private
 */
router.post('/:petId', authenticate, favoriteController.addFavorite);

/**
 * @route   DELETE /api/v1/favorites/:petId
 * @desc    Remove pet from favorites
 * @access  Private
 */
router.delete('/:petId', authenticate, favoriteController.removeFavorite);

module.exports = router;
