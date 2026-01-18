// src/validators/pet.validators.js
const { body, query, validationResult } = require('express-validator');

/**
 * Middleware to handle validation errors
 */
const handleValidationErrors = (req, res, next) => {
  const errors = validationResult(req);

  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      message: 'Validation failed',
      errors: errors.array().map((err) => ({
        field: err.path,
        message: err.msg,
      })),
    });
  }

  next();
};

/**
 * Validation rules for pet filters
 */
const validatePetFilters = [
  query('type')
    .optional()
    .isIn(['dog', 'cat', 'bird', 'rabbit', 'other'])
    .withMessage('Invalid pet type'),

  query('age_category')
    .optional()
    .isIn(['puppy', 'young', 'adult', 'senior'])
    .withMessage('Invalid age category'),

  query('gender')
    .optional()
    .isIn(['male', 'female', 'unknown'])
    .withMessage('Invalid gender'),

  query('size')
    .optional()
    .isIn(['small', 'medium', 'large'])
    .withMessage('Invalid size'),

  query('page')
    .optional()
    .isInt({ min: 1 })
    .withMessage('Page must be a positive integer'),

  query('limit')
    .optional()
    .isInt({ min: 1, max: 50 })
    .withMessage('Limit must be between 1 and 50'),

  handleValidationErrors,
];

/**
 * Validation rules for swipe action
 */
const validateSwipe = [
  body('action')
    .notEmpty()
    .withMessage('Action is required')
    .isIn(['like', 'pass'])
    .withMessage('Action must be "like" or "pass"'),

  handleValidationErrors,
];

module.exports = {
  validatePetFilters,
  validateSwipe,
  handleValidationErrors,
};
