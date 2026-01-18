// src/validators/preference.validators.js
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
 * Validation rules for user preferences
 */
const validatePreferences = [
  body('preferredPetTypes')
    .optional()
    .isArray()
    .withMessage('Preferred pet types must be an array')
    .custom((value) => {
      const validTypes = ['dog', 'cat', 'bird', 'rabbit', 'other'];
      if (value && value.some((type) => !validTypes.includes(type))) {
        throw new Error('Invalid pet type in array');
      }
      return true;
    }),

  body('hasGarden')
    .optional()
    .isBoolean()
    .withMessage('Has garden must be a boolean'),

  body('hasChildren')
    .optional()
    .isBoolean()
    .withMessage('Has children must be a boolean'),

  body('childrenAges')
    .optional()
    .isArray()
    .withMessage('Children ages must be an array')
    .custom((value) => {
      const validAges = ['0-2', '3-5', '6-12', '13+'];
      if (value && value.some((age) => !validAges.includes(age))) {
        throw new Error('Invalid age range in array');
      }
      return true;
    }),

  body('hasOtherPets')
    .optional()
    .isBoolean()
    .withMessage('Has other pets must be a boolean'),

  body('otherPetTypes')
    .optional()
    .isArray()
    .withMessage('Other pet types must be an array')
    .custom((value) => {
      const validTypes = ['dog', 'cat', 'bird', 'rabbit', 'other'];
      if (value && value.some((type) => !validTypes.includes(type))) {
        throw new Error('Invalid pet type in array');
      }
      return true;
    }),

  handleValidationErrors,
];

module.exports = {
  validatePreferences,
};
