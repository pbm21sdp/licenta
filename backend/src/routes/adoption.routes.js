// src/routes/adoption.routes.js
const express = require('express');
const router = express.Router();
const adoptionController = require('../controllers/adoption.controller');
const { authenticate } = require('../middleware/auth');
const {
  validateCreateAdoption,
  validateUpdateAdoption,
} = require('../validators/adoption.validators');

// ==========================================
// ALL ROUTES REQUIRE AUTHENTICATION
// ==========================================

/**
 * @route   GET /api/v1/adoptions
 * @desc    Get user's adoption applications
 * @access  Private
 */
router.get('/', authenticate, adoptionController.getMyAdoptions);

/**
 * @route   GET /api/v1/adoptions/:id
 * @desc    Get single adoption application
 * @access  Private
 */
router.get('/:id', authenticate, adoptionController.getAdoptionById);

/**
 * @route   POST /api/v1/adoptions
 * @desc    Submit new adoption application
 * @access  Private
 */
router.post(
  '/',
  authenticate,
  validateCreateAdoption,
  adoptionController.createAdoption
);

/**
 * @route   PUT /api/v1/adoptions/:id
 * @desc    Update adoption application (if still pending)
 * @access  Private
 */
router.put(
  '/:id',
  authenticate,
  validateUpdateAdoption,
  adoptionController.updateAdoption
);

/**
 * @route   DELETE /api/v1/adoptions/:id
 * @desc    Cancel/withdraw adoption application
 * @access  Private
 */
router.delete('/:id', authenticate, adoptionController.cancelAdoption);

module.exports = router;
