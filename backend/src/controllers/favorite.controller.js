// src/controllers/favorite.controller.js
const { query } = require('../config/database');

// ========================================
// GET USER'S FAVORITES
// ========================================
const getFavorites = async (req, res) => {
  try {
    const userId = req.user.id;
    const { page = 1, limit = 20, sort = 'recent' } = req.query;

    const offset = (parseInt(page) - 1) * parseInt(limit);

    // Determine sort order
    let orderBy;
    switch (sort) {
      case 'alphabetical':
        orderBy = 'p.name ASC';
        break;
      case 'age':
        orderBy = 'p.age_category ASC';
        break;
      case 'breed':
        orderBy = 'p.breed ASC';
        break;
      case 'recent':
      default:
        orderBy = 'f.created_at DESC';
    }

    const favoritesQuery = `
      SELECT
        f.id as favorite_id,
        f.created_at as favorited_at,
        p.id, p.name, p.type, p.breed, p.age_category, p.gender, p.size,
        p.fee, p.is_available, p.adoption_status,
        p.location_city, p.location_country,
        (SELECT photo_url FROM pet_photos WHERE pet_id = p.id AND is_primary = true LIMIT 1) as primary_photo
      FROM favorites f
      JOIN pets p ON f.pet_id = p.id
      WHERE f.user_id = $1
      ORDER BY ${orderBy}
      LIMIT $2 OFFSET $3
    `;

    const countQuery = `
      SELECT COUNT(*) as total
      FROM favorites f
      WHERE f.user_id = $1
    `;

    const [favoritesResult, countResult] = await Promise.all([
      query(favoritesQuery, [userId, parseInt(limit), offset]),
      query(countQuery, [userId]),
    ]);

    const total = parseInt(countResult.rows[0].total);
    const totalPages = Math.ceil(total / parseInt(limit));

    res.status(200).json({
      success: true,
      data: {
        favorites: favoritesResult.rows,
        pagination: {
          currentPage: parseInt(page),
          totalPages,
          totalItems: total,
          itemsPerPage: parseInt(limit),
        },
      },
    });
  } catch (error) {
    console.error('Get favorites error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while fetching favorites.',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// ========================================
// ADD PET TO FAVORITES
// ========================================
const addFavorite = async (req, res) => {
  try {
    const userId = req.user.id;
    const { petId } = req.params;

    // Check if pet exists
    const petResult = await query(
      'SELECT id, name, is_available FROM pets WHERE id = $1',
      [petId]
    );

    if (petResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Pet not found.',
      });
    }

    // Check if already in favorites
    const existingFavorite = await query(
      'SELECT id FROM favorites WHERE user_id = $1 AND pet_id = $2',
      [userId, petId]
    );

    if (existingFavorite.rows.length > 0) {
      return res.status(409).json({
        success: false,
        message: 'Pet is already in your favorites.',
      });
    }

    // Add to favorites
    const result = await query(
      'INSERT INTO favorites (user_id, pet_id) VALUES ($1, $2) RETURNING *',
      [userId, petId]
    );

    res.status(201).json({
      success: true,
      message: 'Pet added to favorites!',
      data: {
        favorite: {
          id: result.rows[0].id,
          petId: result.rows[0].pet_id,
          petName: petResult.rows[0].name,
          createdAt: result.rows[0].created_at,
        },
      },
    });
  } catch (error) {
    console.error('Add favorite error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while adding to favorites.',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// ========================================
// REMOVE PET FROM FAVORITES
// ========================================
const removeFavorite = async (req, res) => {
  try {
    const userId = req.user.id;
    const { petId } = req.params;

    // Check if in favorites
    const existingFavorite = await query(
      'SELECT id FROM favorites WHERE user_id = $1 AND pet_id = $2',
      [userId, petId]
    );

    if (existingFavorite.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Pet is not in your favorites.',
      });
    }

    // Remove from favorites
    await query(
      'DELETE FROM favorites WHERE user_id = $1 AND pet_id = $2',
      [userId, petId]
    );

    res.status(200).json({
      success: true,
      message: 'Pet removed from favorites.',
    });
  } catch (error) {
    console.error('Remove favorite error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while removing from favorites.',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// ========================================
// CHECK IF PET IS FAVORITED
// ========================================
const checkFavorite = async (req, res) => {
  try {
    const userId = req.user.id;
    const { petId } = req.params;

    const result = await query(
      'SELECT id FROM favorites WHERE user_id = $1 AND pet_id = $2',
      [userId, petId]
    );

    res.status(200).json({
      success: true,
      data: {
        isFavorited: result.rows.length > 0,
      },
    });
  } catch (error) {
    console.error('Check favorite error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while checking favorite status.',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// ========================================
// EXPORTS
// ========================================
module.exports = {
  getFavorites,
  addFavorite,
  removeFavorite,
  checkFavorite,
};
