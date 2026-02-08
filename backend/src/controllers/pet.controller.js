// src/controllers/pet.controller.js
const { query } = require('../config/database');

// ========================================
// GET ALL PETS (with filtering and pagination)
// ========================================
const getPets = async (req, res) => {
  try {
    const {
      type,
      breed,
      age_category,
      gender,
      size,
      color,
      city,
      page = 1,
      limit = 20,
    } = req.query;

    let whereConditions = ['p.is_available = true', 'p.adoption_status = $1'];
    let params = ['available'];
    let paramIndex = 2;

    // Build dynamic WHERE clause based on filters
    if (type) {
      whereConditions.push(`p.type = $${paramIndex}`);
      params.push(type);
      paramIndex++;
    }

    if (breed) {
      whereConditions.push(`p.breed ILIKE $${paramIndex}`);
      params.push(`%${breed}%`);
      paramIndex++;
    }

    if (age_category) {
      whereConditions.push(`p.age_category = $${paramIndex}`);
      params.push(age_category);
      paramIndex++;
    }

    if (gender) {
      whereConditions.push(`p.gender = $${paramIndex}`);
      params.push(gender);
      paramIndex++;
    }

    if (size) {
      whereConditions.push(`p.size = $${paramIndex}`);
      params.push(size);
      paramIndex++;
    }

    if (color) {
      whereConditions.push(`p.color ILIKE $${paramIndex}`);
      params.push(`%${color}%`);
      paramIndex++;
    }

    if (city) {
      whereConditions.push(`p.location_city ILIKE $${paramIndex}`);
      params.push(`%${city}%`);
      paramIndex++;
    }

    const offset = (parseInt(page) - 1) * parseInt(limit);
    params.push(parseInt(limit));
    params.push(offset);

    const whereClause = whereConditions.join(' AND ');

    // Get pets with primary photo and owner info
    const petsQuery = `
      SELECT
        p.id, p.name, p.type, p.breed, p.age_category, p.gender, p.size, p.color,
        p.fee, p.description, p.location_city, p.location_country,
        p.created_at, p.owner_id,
        u.name as owner_name, u.avatar_url as owner_avatar,
        (SELECT photo_url FROM pet_photos WHERE pet_id = p.id AND is_primary = true LIMIT 1) as primary_photo
      FROM pets p
      LEFT JOIN users u ON p.owner_id = u.id
      WHERE ${whereClause}
      ORDER BY p.created_at DESC
      LIMIT $${paramIndex} OFFSET $${paramIndex + 1}
    `;

    // Get total count for pagination
    const countQuery = `
      SELECT COUNT(*) as total
      FROM pets p
      WHERE ${whereClause}
    `;

    const [petsResult, countResult] = await Promise.all([
      query(petsQuery, params),
      query(countQuery, params.slice(0, -2)), // Exclude LIMIT and OFFSET params
    ]);

    const total = parseInt(countResult.rows[0].total);
    const totalPages = Math.ceil(total / parseInt(limit));

    res.status(200).json({
      success: true,
      data: {
        pets: petsResult.rows,
        pagination: {
          currentPage: parseInt(page),
          totalPages,
          totalItems: total,
          itemsPerPage: parseInt(limit),
        },
      },
    });
  } catch (error) {
    console.error('Get pets error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while fetching pets.',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// ========================================
// GET PETS FOR SWIPING (excludes already swiped)
// ========================================
const getSwipePets = async (req, res) => {
  try {
    const userId = req.user.id;
    const { limit = 10 } = req.query;

    // Get user preferences for personalized results
    const prefsResult = await query(
      'SELECT * FROM user_preferences WHERE user_id = $1',
      [userId]
    );
    const preferences = prefsResult.rows[0];

    let whereConditions = [
      'p.is_available = true',
      'p.adoption_status = $1',
      'p.id NOT IN (SELECT pet_id FROM user_swipes WHERE user_id = $2)',
    ];
    let params = ['available', userId];
    let paramIndex = 3;

    // Apply user preferences if they exist
    if (preferences && preferences.preferred_pet_types && preferences.preferred_pet_types.length > 0) {
      whereConditions.push(`p.type = ANY($${paramIndex})`);
      params.push(preferences.preferred_pet_types);
      paramIndex++;
    }

    params.push(parseInt(limit));

    const petsQuery = `
      SELECT
        p.id, p.name, p.type, p.breed, p.age_category, p.gender, p.size, p.color,
        p.fee, p.description, p.health_status, p.story,
        p.location_city, p.location_country, p.owner_id,
        u.name as owner_name, u.avatar_url as owner_avatar,
        (SELECT photo_url FROM pet_photos WHERE pet_id = p.id AND is_primary = true LIMIT 1) as primary_photo,
        (SELECT json_agg(photo_url) FROM pet_photos WHERE pet_id = p.id) as photos,
        (SELECT json_agg(trait) FROM pet_traits WHERE pet_id = p.id) as traits
      FROM pets p
      LEFT JOIN users u ON p.owner_id = u.id
      WHERE ${whereConditions.join(' AND ')}
      ORDER BY RANDOM()
      LIMIT $${paramIndex}
    `;

    const result = await query(petsQuery, params);

    res.status(200).json({
      success: true,
      data: {
        pets: result.rows,
        remaining: result.rows.length,
      },
    });
  } catch (error) {
    console.error('Get swipe pets error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while fetching pets for swiping.',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// ========================================
// GET SINGLE PET BY ID
// ========================================
const getPetById = async (req, res) => {
  try {
    const { id } = req.params;
    const currentUserId = req.user?.id; // Poate fi undefined pentru vizitatori anonimi

    const petQuery = `
      SELECT
        p.*,
        u.id as owner_id,
        u.name as owner_name,
        u.avatar_url as owner_avatar,
        (SELECT json_agg(json_build_object('id', id, 'url', photo_url, 'is_primary', is_primary))
         FROM pet_photos WHERE pet_id = p.id) as photos,
        (SELECT json_agg(trait) FROM pet_traits WHERE pet_id = p.id) as traits
      FROM pets p
      LEFT JOIN users u ON p.owner_id = u.id
      WHERE p.id = $1
    `;

    const result = await query(petQuery, [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Pet not found.',
      });
    }

    const pet = result.rows[0];

    // Adaugă un flag pentru a indica dacă utilizatorul curent este owner-ul
    const isCurrentUserOwner = currentUserId && pet.owner_id === currentUserId;

    res.status(200).json({
      success: true,
      data: {
        pet: {
          ...pet,
          isCurrentUserOwner,
        },
      },
    });
  } catch (error) {
    console.error('Get pet by ID error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while fetching pet details.',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// ========================================
// RECORD SWIPE ACTION
// ========================================
const swipePet = async (req, res) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;
    const { action } = req.body; // 'like' or 'pass'

    // Validate action
    if (!['like', 'pass'].includes(action)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid action. Must be "like" or "pass".',
      });
    }

    // Check if pet exists
    const petResult = await query('SELECT id, name FROM pets WHERE id = $1', [id]);
    if (petResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Pet not found.',
      });
    }

    // Check if already swiped
    const existingSwipe = await query(
      'SELECT id FROM user_swipes WHERE user_id = $1 AND pet_id = $2',
      [userId, id]
    );

    if (existingSwipe.rows.length > 0) {
      return res.status(409).json({
        success: false,
        message: 'You have already swiped on this pet.',
      });
    }

    // Record the swipe
    await query(
      'INSERT INTO user_swipes (user_id, pet_id, action) VALUES ($1, $2, $3)',
      [userId, id, action]
    );

    // If liked, optionally add to favorites
    if (action === 'like') {
      // Check if not already in favorites
      const existingFavorite = await query(
        'SELECT id FROM favorites WHERE user_id = $1 AND pet_id = $2',
        [userId, id]
      );

      if (existingFavorite.rows.length === 0) {
        await query(
          'INSERT INTO favorites (user_id, pet_id) VALUES ($1, $2)',
          [userId, id]
        );
      }
    }

    res.status(201).json({
      success: true,
      message: action === 'like'
        ? 'Pet liked and added to favorites!'
        : 'Pet passed.',
      data: {
        petId: id,
        action,
      },
    });
  } catch (error) {
    console.error('Swipe pet error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while recording your swipe.',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// ========================================
// UNDO LAST SWIPE
// ========================================
const undoSwipe = async (req, res) => {
  try {
    const userId = req.user.id;

    // Get the most recent swipe
    const lastSwipe = await query(
      `SELECT id, pet_id, action FROM user_swipes
       WHERE user_id = $1
       ORDER BY created_at DESC
       LIMIT 1`,
      [userId]
    );

    if (lastSwipe.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'No swipes to undo.',
      });
    }

    const swipe = lastSwipe.rows[0];

    // Delete the swipe
    await query('DELETE FROM user_swipes WHERE id = $1', [swipe.id]);

    // If it was a like, also remove from favorites
    if (swipe.action === 'like') {
      await query(
        'DELETE FROM favorites WHERE user_id = $1 AND pet_id = $2',
        [userId, swipe.pet_id]
      );
    }

    res.status(200).json({
      success: true,
      message: 'Last swipe undone successfully.',
      data: {
        petId: swipe.pet_id,
        undoneAction: swipe.action,
      },
    });
  } catch (error) {
    console.error('Undo swipe error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while undoing the swipe.',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// ========================================
// EXPORTS
// ========================================
module.exports = {
  getPets,
  getSwipePets,
  getPetById,
  swipePet,
  undoSwipe,
};
