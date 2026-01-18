// src/routes/admin.routes.js
const express = require('express');
const router = express.Router();
const adminController = require('../controllers/admin.controller');
const { authenticate, requireAdmin } = require('../middleware/auth');
const {
  validateCreatePet,
  validateUpdatePet,
  validateUpdateAdoptionStatus,
  validateScheduleMeeting,
  validateAddPhoto,
} = require('../validators/admin.validators');

// ==========================================
// ALL ROUTES REQUIRE ADMIN AUTHENTICATION
// ==========================================

// Apply auth and admin middleware to all routes
router.use(authenticate);
router.use(requireAdmin);

// ==========================================
// DASHBOARD
// ==========================================

/**
 * @route   GET /api/v1/admin/dashboard
 * @desc    Get dashboard statistics
 * @access  Admin
 */
router.get('/dashboard', adminController.getDashboardStats);

// ==========================================
// PET MANAGEMENT
// ==========================================

/**
 * @route   GET /api/v1/admin/pets
 * @desc    Get all pets (including unavailable)
 * @access  Admin
 */
router.get('/pets', adminController.getAllPets);

/**
 * @route   POST /api/v1/admin/pets
 * @desc    Create new pet
 * @access  Admin
 */
router.post('/pets', validateCreatePet, adminController.createPet);

/**
 * @route   PUT /api/v1/admin/pets/:id
 * @desc    Update pet
 * @access  Admin
 */
router.put('/pets/:id', validateUpdatePet, adminController.updatePet);

/**
 * @route   DELETE /api/v1/admin/pets/:id
 * @desc    Delete pet
 * @access  Admin
 */
router.delete('/pets/:id', adminController.deletePet);

/**
 * @route   POST /api/v1/admin/pets/:id/photos
 * @desc    Add photo to pet
 * @access  Admin
 */
router.post('/pets/:id/photos', validateAddPhoto, adminController.addPetPhoto);

/**
 * @route   DELETE /api/v1/admin/pets/:id/photos/:photoId
 * @desc    Delete pet photo
 * @access  Admin
 */
router.delete('/pets/:id/photos/:photoId', adminController.deletePetPhoto);

// ==========================================
// ADOPTION MANAGEMENT
// ==========================================

/**
 * @route   GET /api/v1/admin/adoptions
 * @desc    Get all adoption applications
 * @access  Admin
 */
router.get('/adoptions', adminController.getAllAdoptions);

/**
 * @route   GET /api/v1/admin/adoptions/:id
 * @desc    Get adoption application details
 * @access  Admin
 */
router.get('/adoptions/:id', adminController.getAdoptionDetails);

/**
 * @route   PUT /api/v1/admin/adoptions/:id/status
 * @desc    Update adoption status
 * @access  Admin
 */
router.put(
  '/adoptions/:id/status',
  validateUpdateAdoptionStatus,
  adminController.updateAdoptionStatus
);

/**
 * @route   POST /api/v1/admin/adoptions/:id/meeting
 * @desc    Schedule meeting for adoption
 * @access  Admin
 */
router.post(
  '/adoptions/:id/meeting',
  validateScheduleMeeting,
  adminController.scheduleMeeting
);

module.exports = router;
