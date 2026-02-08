// src/routes/admin.routes.js
// ==========================================
// DEPRECATED: Admin routes have been replaced with peer-to-peer model
// Pet owners now manage their own pets and adoption requests
// See: /api/v1/my-pets for pet management
// See: /api/v1/owner/adoptions for adoption request management
// ==========================================

const express = require('express');
const router = express.Router();

// Return deprecation message for all admin routes
router.use((req, res) => {
  return res.status(410).json({
    success: false,
    message: 'Admin routes have been deprecated. The application now uses a peer-to-peer model where pet owners manage their own pets and adoption requests.',
    alternatives: {
      petManagement: '/api/v1/my-pets',
      adoptionRequests: '/api/v1/owner/adoptions',
      publicProfiles: '/api/v1/users/:id/profile',
    },
  });
});

module.exports = router;
