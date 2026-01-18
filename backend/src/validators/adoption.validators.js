// src/validators/adoption.validators.js
const { body, validationResult } = require('express-validator');

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
 * Validation rules for creating adoption application
 */
const validateCreateAdoption = [
  body('petId')
    .notEmpty()
    .withMessage('Pet ID is required')
    .isInt({ min: 1 })
    .withMessage('Pet ID must be a valid integer'),

  body('fullName')
    .trim()
    .notEmpty()
    .withMessage('Full name is required')
    .isLength({ min: 2, max: 100 })
    .withMessage('Full name must be between 2 and 100 characters'),

  body('email')
    .trim()
    .isEmail()
    .withMessage('Please provide a valid email address')
    .normalizeEmail(),

  body('phone')
    .trim()
    .notEmpty()
    .withMessage('Phone number is required')
    .isLength({ max: 50 })
    .withMessage('Phone number is too long'),

  body('address')
    .trim()
    .notEmpty()
    .withMessage('Address is required')
    .isLength({ max: 255 })
    .withMessage('Address is too long'),

  body('city')
    .trim()
    .notEmpty()
    .withMessage('City is required')
    .isLength({ max: 100 })
    .withMessage('City name is too long'),

  body('postalCode')
    .trim()
    .notEmpty()
    .withMessage('Postal code is required')
    .isLength({ max: 20 })
    .withMessage('Postal code is too long'),

  body('housingType')
    .optional()
    .trim()
    .isIn(['house', 'apartment', 'condo', 'townhouse', 'other'])
    .withMessage('Invalid housing type'),

  body('hasYard')
    .optional()
    .isIn(['yes', 'no', 'shared'])
    .withMessage('Has yard must be yes, no, or shared'),

  body('hasChildren')
    .optional()
    .isBoolean()
    .withMessage('Has children must be a boolean'),

  body('hasOtherPets')
    .optional()
    .isBoolean()
    .withMessage('Has other pets must be a boolean'),

  body('adoptionReason')
    .trim()
    .notEmpty()
    .withMessage('Please tell us why you want to adopt')
    .isLength({ max: 2000 })
    .withMessage('Adoption reason is too long'),

  handleValidationErrors,
];

/**
 * Validation rules for updating adoption application
 */
const validateUpdateAdoption = [
  body('fullName')
    .optional()
    .trim()
    .isLength({ min: 2, max: 100 })
    .withMessage('Full name must be between 2 and 100 characters'),

  body('phone')
    .optional()
    .trim()
    .isLength({ max: 50 })
    .withMessage('Phone number is too long'),

  body('address')
    .optional()
    .trim()
    .isLength({ max: 255 })
    .withMessage('Address is too long'),

  body('city')
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage('City name is too long'),

  body('postalCode')
    .optional()
    .trim()
    .isLength({ max: 20 })
    .withMessage('Postal code is too long'),

  body('housingType')
    .optional()
    .trim()
    .isIn(['house', 'apartment', 'condo', 'townhouse', 'other'])
    .withMessage('Invalid housing type'),

  body('hasYard')
    .optional()
    .isIn(['yes', 'no', 'shared'])
    .withMessage('Has yard must be yes, no, or shared'),

  body('adoptionReason')
    .optional()
    .trim()
    .isLength({ max: 2000 })
    .withMessage('Adoption reason is too long'),

  handleValidationErrors,
];

module.exports = {
  validateCreateAdoption,
  validateUpdateAdoption,
};
