// src/routes/user-pets.routes.js
// Rute pentru gestionarea animalelor proprii

const express = require('express');
const router = express.Router();
const userPetsController = require('../controllers/user-pets.controller');
const { authenticate, requireVerified } = require('../middleware/auth');

// ==========================================
// ALL ROUTES REQUIRE AUTHENTICATION
// ==========================================

// Apply auth middleware to all routes
router.use(authenticate);
router.use(requireVerified);

// ==========================================
// MY PETS ROUTES
// ==========================================

/**
 * @route   GET /api/v1/my-pets
 * @desc    Get all pets owned by current user
 * @access  Private
 */
router.get('/', userPetsController.getMyPets);

/**
 * @route   POST /api/v1/my-pets
 * @desc    Create/list a new pet
 * @access  Private
 */
router.post('/', userPetsController.createPet);

/**
 * @route   GET /api/v1/my-pets/:id
 * @desc    Get single pet owned by current user
 * @access  Private
 */
router.get('/:id', userPetsController.getMyPetById);

/**
 * @route   PUT /api/v1/my-pets/:id
 * @desc    Update pet (only if owner)
 * @access  Private
 */
router.put('/:id', userPetsController.updatePet);

/**
 * @route   DELETE /api/v1/my-pets/:id
 * @desc    Delete pet (only if owner)
 * @access  Private
 */
router.delete('/:id', userPetsController.deletePet);

/**
 * @route   POST /api/v1/my-pets/:id/photos
 * @desc    Add photo to pet
 * @access  Private
 */
router.post('/:id/photos', userPetsController.addPetPhoto);

/**
 * @route   DELETE /api/v1/my-pets/:id/photos/:photoId
 * @desc    Delete pet photo
 * @access  Private
 */
router.delete('/:id/photos/:photoId', userPetsController.deletePetPhoto);

module.exports = router;
