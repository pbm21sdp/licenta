// src/routes/owner-adoptions.routes.js
// Rute pentru gestionarea cererilor de adopție din perspectiva owner-ului

const express = require('express');
const router = express.Router();
const ownerAdoptionsController = require('../controllers/owner-adoptions.controller');
const { authenticate, requireVerified } = require('../middleware/auth');

// ==========================================
// ALL ROUTES REQUIRE AUTHENTICATION
// ==========================================

// Apply auth middleware to all routes
router.use(authenticate);
router.use(requireVerified);

// ==========================================
// OWNER ADOPTION ROUTES
// ==========================================

/**
 * @route   GET /api/v1/owner/adoptions
 * @desc    Get all adoption requests for my pets
 * @access  Private
 */
router.get('/', ownerAdoptionsController.getMyAdoptionRequests);

/**
 * @route   GET /api/v1/owner/adoptions/stats
 * @desc    Get owner statistics
 * @access  Private
 */
router.get('/stats', ownerAdoptionsController.getOwnerStats);

/**
 * @route   GET /api/v1/owner/adoptions/:id
 * @desc    Get single adoption request details
 * @access  Private
 */
router.get('/:id', ownerAdoptionsController.getAdoptionRequestById);

/**
 * @route   PUT /api/v1/owner/adoptions/:id/status
 * @desc    Update adoption status (approve/reject)
 * @access  Private
 */
router.put('/:id/status', ownerAdoptionsController.updateAdoptionStatus);

/**
 * @route   POST /api/v1/owner/adoptions/:id/meeting
 * @desc    Schedule meeting for adoption
 * @access  Private
 */
router.post('/:id/meeting', ownerAdoptionsController.scheduleMeeting);

module.exports = router;
