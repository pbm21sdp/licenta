// src/validators/admin.validators.js
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
 * Validation rules for creating a pet
 */
const validateCreatePet = [
  body('name')
    .trim()
    .notEmpty()
    .withMessage('Pet name is required')
    .isLength({ min: 1, max: 100 })
    .withMessage('Pet name must be between 1 and 100 characters'),

  body('type')
    .notEmpty()
    .withMessage('Pet type is required')
    .isIn(['dog', 'cat', 'bird', 'rabbit', 'other'])
    .withMessage('Invalid pet type'),

  body('breed')
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage('Breed name is too long'),

  body('ageCategory')
    .optional()
    .isIn(['puppy', 'young', 'adult', 'senior'])
    .withMessage('Invalid age category'),

  body('gender')
    .optional()
    .isIn(['male', 'female', 'unknown'])
    .withMessage('Invalid gender'),

  body('size')
    .optional()
    .isIn(['small', 'medium', 'large'])
    .withMessage('Invalid size'),

  body('color')
    .optional()
    .trim()
    .isLength({ max: 50 })
    .withMessage('Color is too long'),

  body('coat')
    .optional()
    .isIn(['short', 'medium', 'long'])
    .withMessage('Invalid coat type'),

  body('fee')
    .optional()
    .isFloat({ min: 0 })
    .withMessage('Fee must be a positive number'),

  body('description')
    .optional()
    .trim()
    .isLength({ max: 5000 })
    .withMessage('Description is too long'),

  body('healthStatus')
    .optional()
    .trim()
    .isLength({ max: 5000 })
    .withMessage('Health status is too long'),

  body('story')
    .optional()
    .trim()
    .isLength({ max: 5000 })
    .withMessage('Story is too long'),

  body('locationCity')
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage('City name is too long'),

  body('locationCountry')
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage('Country name is too long'),

  body('shelterContactEmail')
    .optional()
    .trim()
    .isEmail()
    .withMessage('Invalid shelter email'),

  body('shelterContactPhone')
    .optional()
    .trim()
    .isLength({ max: 50 })
    .withMessage('Phone number is too long'),

  body('traits')
    .optional()
    .isArray()
    .withMessage('Traits must be an array'),

  body('photos')
    .optional()
    .isArray()
    .withMessage('Photos must be an array'),

  handleValidationErrors,
];

/**
 * Validation rules for updating a pet
 */
const validateUpdatePet = [
  body('name')
    .optional()
    .trim()
    .isLength({ min: 1, max: 100 })
    .withMessage('Pet name must be between 1 and 100 characters'),

  body('type')
    .optional()
    .isIn(['dog', 'cat', 'bird', 'rabbit', 'other'])
    .withMessage('Invalid pet type'),

  body('breed')
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage('Breed name is too long'),

  body('ageCategory')
    .optional()
    .isIn(['puppy', 'young', 'adult', 'senior'])
    .withMessage('Invalid age category'),

  body('gender')
    .optional()
    .isIn(['male', 'female', 'unknown'])
    .withMessage('Invalid gender'),

  body('size')
    .optional()
    .isIn(['small', 'medium', 'large'])
    .withMessage('Invalid size'),

  body('adoptionStatus')
    .optional()
    .isIn(['available', 'pending', 'in_review', 'adopted'])
    .withMessage('Invalid adoption status'),

  body('isAvailable')
    .optional()
    .isBoolean()
    .withMessage('Is available must be a boolean'),

  handleValidationErrors,
];

/**
 * Validation rules for updating adoption status
 */
const validateUpdateAdoptionStatus = [
  body('status')
    .notEmpty()
    .withMessage('Status is required')
    .isIn(['pending', 'in_review', 'approved', 'rejected'])
    .withMessage('Invalid status'),

  body('adminNotes')
    .optional()
    .trim()
    .isLength({ max: 2000 })
    .withMessage('Admin notes are too long'),

  handleValidationErrors,
];

/**
 * Validation rules for scheduling a meeting
 */
const validateScheduleMeeting = [
  body('scheduledDate')
    .notEmpty()
    .withMessage('Scheduled date is required')
    .isISO8601()
    .withMessage('Invalid date format'),

  body('scheduledTime')
    .notEmpty()
    .withMessage('Scheduled time is required')
    .isLength({ max: 20 })
    .withMessage('Time format is too long'),

  body('location')
    .trim()
    .notEmpty()
    .withMessage('Location is required')
    .isLength({ max: 255 })
    .withMessage('Location is too long'),

  body('notes')
    .optional()
    .trim()
    .isLength({ max: 2000 })
    .withMessage('Notes are too long'),

  handleValidationErrors,
];

/**
 * Validation rules for adding a photo
 */
const validateAddPhoto = [
  body('url')
    .trim()
    .notEmpty()
    .withMessage('Photo URL is required')
    .isURL()
    .withMessage('Invalid URL format'),

  body('isPrimary')
    .optional()
    .isBoolean()
    .withMessage('Is primary must be a boolean'),

  handleValidationErrors,
];

module.exports = {
  validateCreatePet,
  validateUpdatePet,
  validateUpdateAdoptionStatus,
  validateScheduleMeeting,
  validateAddPhoto,
};
