// src/controllers/preference.controller.js
const { query } = require('../config/database');

// ========================================
// GET USER PREFERENCES
// ========================================
const getPreferences = async (req, res) => {
  try {
    const userId = req.user.id;

    const result = await query(
      'SELECT * FROM user_preferences WHERE user_id = $1',
      [userId]
    );

    if (result.rows.length === 0) {
      return res.status(200).json({
        success: true,
        data: {
          preferences: null,
          message: 'No preferences set. Complete the onboarding questionnaire to set your preferences.',
        },
      });
    }

    res.status(200).json({
      success: true,
      data: {
        preferences: {
          preferredPetTypes: result.rows[0].preferred_pet_types,
          hasGarden: result.rows[0].has_garden,
          hasChildren: result.rows[0].has_children,
          childrenAges: result.rows[0].children_ages,
          hasOtherPets: result.rows[0].has_other_pets,
          otherPetTypes: result.rows[0].other_pet_types,
          updatedAt: result.rows[0].updated_at,
        },
      },
    });
  } catch (error) {
    console.error('Get preferences error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while fetching preferences.',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// ========================================
// CREATE/SAVE USER PREFERENCES (from onboarding)
// ========================================
const createPreferences = async (req, res) => {
  try {
    const userId = req.user.id;
    const {
      preferredPetTypes,
      hasGarden,
      hasChildren,
      childrenAges,
      hasOtherPets,
      otherPetTypes,
    } = req.body;

    // Check if preferences already exist
    const existingResult = await query(
      'SELECT id FROM user_preferences WHERE user_id = $1',
      [userId]
    );

    let result;

    if (existingResult.rows.length > 0) {
      // Update existing preferences
      result = await query(
        `UPDATE user_preferences
         SET preferred_pet_types = $1,
             has_garden = $2,
             has_children = $3,
             children_ages = $4,
             has_other_pets = $5,
             other_pet_types = $6
         WHERE user_id = $7
         RETURNING *`,
        [
          preferredPetTypes || [],
          hasGarden,
          hasChildren,
          childrenAges || [],
          hasOtherPets,
          otherPetTypes || [],
          userId,
        ]
      );
    } else {
      // Create new preferences
      result = await query(
        `INSERT INTO user_preferences (
           user_id, preferred_pet_types, has_garden, has_children,
           children_ages, has_other_pets, other_pet_types
         ) VALUES ($1, $2, $3, $4, $5, $6, $7)
         RETURNING *`,
        [
          userId,
          preferredPetTypes || [],
          hasGarden,
          hasChildren,
          childrenAges || [],
          hasOtherPets,
          otherPetTypes || [],
        ]
      );
    }

    res.status(201).json({
      success: true,
      message: 'Preferences saved successfully!',
      data: {
        preferences: {
          preferredPetTypes: result.rows[0].preferred_pet_types,
          hasGarden: result.rows[0].has_garden,
          hasChildren: result.rows[0].has_children,
          childrenAges: result.rows[0].children_ages,
          hasOtherPets: result.rows[0].has_other_pets,
          otherPetTypes: result.rows[0].other_pet_types,
        },
      },
    });
  } catch (error) {
    console.error('Create preferences error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while saving preferences.',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// ========================================
// UPDATE USER PREFERENCES
// ========================================
const updatePreferences = async (req, res) => {
  try {
    const userId = req.user.id;
    const updates = req.body;

    // Check if preferences exist
    const existingResult = await query(
      'SELECT id FROM user_preferences WHERE user_id = $1',
      [userId]
    );

    if (existingResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'No preferences found. Please create preferences first.',
      });
    }

    // Build update query dynamically
    const fieldMapping = {
      preferredPetTypes: 'preferred_pet_types',
      hasGarden: 'has_garden',
      hasChildren: 'has_children',
      childrenAges: 'children_ages',
      hasOtherPets: 'has_other_pets',
      otherPetTypes: 'other_pet_types',
    };

    const updateFields = [];
    const params = [];
    let paramIndex = 1;

    for (const [key, value] of Object.entries(updates)) {
      if (fieldMapping[key]) {
        updateFields.push(`${fieldMapping[key]} = $${paramIndex}`);
        params.push(value);
        paramIndex++;
      }
    }

    if (updateFields.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'No valid fields to update.',
      });
    }

    params.push(userId);

    const updateQuery = `
      UPDATE user_preferences
      SET ${updateFields.join(', ')}
      WHERE user_id = $${paramIndex}
      RETURNING *
    `;

    const result = await query(updateQuery, params);

    res.status(200).json({
      success: true,
      message: 'Preferences updated successfully!',
      data: {
        preferences: {
          preferredPetTypes: result.rows[0].preferred_pet_types,
          hasGarden: result.rows[0].has_garden,
          hasChildren: result.rows[0].has_children,
          childrenAges: result.rows[0].children_ages,
          hasOtherPets: result.rows[0].has_other_pets,
          otherPetTypes: result.rows[0].other_pet_types,
        },
      },
    });
  } catch (error) {
    console.error('Update preferences error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while updating preferences.',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// ========================================
// DELETE USER PREFERENCES
// ========================================
const deletePreferences = async (req, res) => {
  try {
    const userId = req.user.id;

    const result = await query(
      'DELETE FROM user_preferences WHERE user_id = $1 RETURNING id',
      [userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'No preferences found to delete.',
      });
    }

    res.status(200).json({
      success: true,
      message: 'Preferences deleted successfully.',
    });
  } catch (error) {
    console.error('Delete preferences error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while deleting preferences.',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// ========================================
// EXPORTS
// ========================================
module.exports = {
  getPreferences,
  createPreferences,
  updatePreferences,
  deletePreferences,
};
