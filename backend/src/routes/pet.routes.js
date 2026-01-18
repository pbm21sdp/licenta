// src/routes/pet.routes.js
const express = require('express');
const router = express.Router();
const petController = require('../controllers/pet.controller');
const { authenticate } = require('../middleware/auth');
const {
  validateSwipe,
  validatePetFilters,
} = require('../validators/pet.validators');

// ==========================================
// PUBLIC ROUTES
// ==========================================

/**
 * @route   GET /api/v1/pets
 * @desc    Get all available pets with filters
 * @access  Public
 */
router.get('/', validatePetFilters, petController.getPets);

/**
 * @route   GET /api/v1/pets/:id
 * @desc    Get single pet by ID
 * @access  Public
 */
router.get('/:id', petController.getPetById);

// ==========================================
// PROTECTED ROUTES
// ==========================================

/**
 * @route   GET /api/v1/pets/feed/swipe
 * @desc    Get pets for swiping (excludes already swiped)
 * @access  Private
 */
router.get('/feed/swipe', authenticate, petController.getSwipePets);

/**
 * @route   POST /api/v1/pets/:id/swipe
 * @desc    Record swipe action (like/pass)
 * @access  Private
 */
router.post('/:id/swipe', authenticate, validateSwipe, petController.swipePet);

/**
 * @route   POST /api/v1/pets/swipe/undo
 * @desc    Undo last swipe
 * @access  Private
 */
router.post('/swipe/undo', authenticate, petController.undoSwipe);

module.exports = router;
