// src/controllers/user-profile.controller.js
// Controller pentru profile publice și căutare utilizatori

const { query } = require('../config/database');

// ========================================
// GET PUBLIC PROFILE - Profilul public al unui utilizator
// ========================================
const getPublicProfile = async (req, res) => {
  try {
    const { id } = req.params;

    const userQuery = `
      SELECT
        u.id, u.name, u.avatar_url, u.created_at,
        (SELECT COUNT(*) FROM pets WHERE owner_id = u.id) as total_pets,
        (SELECT COUNT(*) FROM pets WHERE owner_id = u.id AND is_available = true) as available_pets,
        (SELECT COUNT(*) FROM pets WHERE owner_id = u.id AND adoption_status = 'adopted') as adopted_pets
      FROM users u
      WHERE u.id = $1 AND u.deleted_at IS NULL
    `;

    const result = await query(userQuery, [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found.',
      });
    }

    const user = result.rows[0];

    res.status(200).json({
      success: true,
      data: {
        profile: {
          id: user.id,
          name: user.name || 'Anonymous User',
          avatar: user.avatar_url,
          memberSince: user.created_at,
          stats: {
            totalPets: parseInt(user.total_pets),
            availablePets: parseInt(user.available_pets),
            adoptedPets: parseInt(user.adopted_pets),
          },
        },
      },
    });
  } catch (error) {
    console.error('Get public profile error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while fetching the profile.',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// ========================================
// GET USER'S PETS - Animalele publice ale unui utilizator
// ========================================
const getUserPets = async (req, res) => {
  try {
    const { id } = req.params;
    const { page = 1, limit = 20, status } = req.query;

    const offset = (parseInt(page) - 1) * parseInt(limit);

    // Verifică dacă utilizatorul există
    const userCheck = await query(
      'SELECT id, name FROM users WHERE id = $1 AND deleted_at IS NULL',
      [id]
    );

    if (userCheck.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found.',
      });
    }

    let whereConditions = ['p.owner_id = $1'];
    let params = [id];
    let paramIndex = 2;

    // Implicit arată doar animalele disponibile pentru utilizatori anonimi
    // Owner-ul poate vedea toate animalele sale
    if (status) {
      whereConditions.push(`p.adoption_status = $${paramIndex}`);
      params.push(status);
      paramIndex++;
    } else {
      // Pentru profiluri publice, arată doar animalele disponibile sau adoptate
      whereConditions.push(`p.adoption_status IN ('available', 'adopted')`);
    }

    params.push(parseInt(limit));
    params.push(offset);

    const petsQuery = `
      SELECT
        p.id, p.name, p.type, p.breed, p.age_category, p.gender, p.size,
        p.location_city, p.is_available, p.adoption_status, p.created_at,
        (SELECT photo_url FROM pet_photos WHERE pet_id = p.id AND is_primary = true LIMIT 1) as primary_photo
      FROM pets p
      WHERE ${whereConditions.join(' AND ')}
      ORDER BY p.created_at DESC
      LIMIT $${paramIndex} OFFSET $${paramIndex + 1}
    `;

    const countQuery = `
      SELECT COUNT(*) as total
      FROM pets p
      WHERE ${whereConditions.join(' AND ')}
    `;

    const [petsResult, countResult] = await Promise.all([
      query(petsQuery, params),
      query(countQuery, params.slice(0, -2)),
    ]);

    const total = parseInt(countResult.rows[0].total);
    const totalPages = Math.ceil(total / parseInt(limit));

    res.status(200).json({
      success: true,
      data: {
        owner: {
          id: userCheck.rows[0].id,
          name: userCheck.rows[0].name || 'Anonymous User',
        },
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
    console.error('Get user pets error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while fetching pets.',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// ========================================
// SEARCH USERS - Căutare utilizatori după nume
// ========================================
const searchUsers = async (req, res) => {
  try {
    const { q, page = 1, limit = 20 } = req.query;

    if (!q || q.length < 2) {
      return res.status(400).json({
        success: false,
        message: 'Search query must be at least 2 characters.',
      });
    }

    const offset = (parseInt(page) - 1) * parseInt(limit);

    const searchQuery = `
      SELECT
        u.id, u.name, u.avatar_url, u.created_at,
        (SELECT COUNT(*) FROM pets WHERE owner_id = u.id AND is_available = true) as available_pets
      FROM users u
      WHERE u.name ILIKE $1
        AND u.deleted_at IS NULL
        AND EXISTS (SELECT 1 FROM pets WHERE owner_id = u.id)
      ORDER BY
        (SELECT COUNT(*) FROM pets WHERE owner_id = u.id) DESC,
        u.name ASC
      LIMIT $2 OFFSET $3
    `;

    const countQuery = `
      SELECT COUNT(*) as total
      FROM users u
      WHERE u.name ILIKE $1
        AND u.deleted_at IS NULL
        AND EXISTS (SELECT 1 FROM pets WHERE owner_id = u.id)
    `;

    const searchPattern = `%${q}%`;

    const [usersResult, countResult] = await Promise.all([
      query(searchQuery, [searchPattern, parseInt(limit), offset]),
      query(countQuery, [searchPattern]),
    ]);

    const total = parseInt(countResult.rows[0].total);
    const totalPages = Math.ceil(total / parseInt(limit));

    res.status(200).json({
      success: true,
      data: {
        users: usersResult.rows.map(user => ({
          id: user.id,
          name: user.name || 'Anonymous User',
          avatar: user.avatar_url,
          memberSince: user.created_at,
          availablePets: parseInt(user.available_pets),
        })),
        pagination: {
          currentPage: parseInt(page),
          totalPages,
          totalItems: total,
          itemsPerPage: parseInt(limit),
        },
      },
    });
  } catch (error) {
    console.error('Search users error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while searching users.',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// ========================================
// GET TOP LISTERS - Utilizatorii cu cele mai multe animale listate
// ========================================
const getTopListers = async (req, res) => {
  try {
    const { limit = 10 } = req.query;

    const listersQuery = `
      SELECT
        u.id, u.name, u.avatar_url, u.created_at,
        COUNT(DISTINCT p.id) as total_pets,
        COUNT(DISTINCT p.id) FILTER (WHERE p.is_available = true) as available_pets,
        COUNT(DISTINCT p.id) FILTER (WHERE p.adoption_status = 'adopted') as adopted_pets
      FROM users u
      LEFT JOIN pets p ON p.owner_id = u.id
      WHERE u.deleted_at IS NULL
      GROUP BY u.id
      HAVING COUNT(p.id) > 0
      ORDER BY total_pets DESC
      LIMIT $1
    `;

    const result = await query(listersQuery, [parseInt(limit)]);

    res.status(200).json({
      success: true,
      data: {
        topListers: result.rows.map(user => ({
          id: user.id,
          name: user.name || 'Anonymous User',
          avatar: user.avatar_url,
          memberSince: user.created_at,
          stats: {
            totalPets: parseInt(user.total_pets),
            availablePets: parseInt(user.available_pets),
            adoptedPets: parseInt(user.adopted_pets),
          },
        })),
      },
    });
  } catch (error) {
    console.error('Get top listers error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while fetching top listers.',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// ========================================
// EXPORTS
// ========================================
module.exports = {
  getPublicProfile,
  getUserPets,
  searchUsers,
  getTopListers,
};
