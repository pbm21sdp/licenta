// src/controllers/user-pets.controller.js
// Controller pentru gestionarea animalelor proprii (CRUD cu verificare ownership)

const { query, getClient } = require('../config/database');

// ========================================
// GET MY PETS - Animalele utilizatorului curent
// ========================================
const getMyPets = async (req, res) => {
  try {
    const userId = req.user.id;
    const { status, page = 1, limit = 20 } = req.query;

    const offset = (parseInt(page) - 1) * parseInt(limit);

    let whereConditions = ['p.owner_id = $1'];
    let params = [userId];
    let paramIndex = 2;

    if (status) {
      whereConditions.push(`p.adoption_status = $${paramIndex}`);
      params.push(status);
      paramIndex++;
    }

    params.push(parseInt(limit));
    params.push(offset);

    const petsQuery = `
      SELECT
        p.*,
        (SELECT photo_url FROM pet_photos WHERE pet_id = p.id AND is_primary = true LIMIT 1) as primary_photo,
        (SELECT COUNT(*) FROM favorites WHERE pet_id = p.id) as favorite_count,
        (SELECT COUNT(*) FROM adoptions WHERE pet_id = p.id AND status IN ('pending', 'in_review')) as pending_applications
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
    console.error('Get my pets error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while fetching your pets.',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// ========================================
// CREATE PET - Adaugă animal nou
// ========================================
const createPet = async (req, res) => {
  const client = await getClient();

  try {
    await client.query('BEGIN');

    const userId = req.user.id;
    const userName = req.user.name;
    const userEmail = req.user.email;

    const {
      name, type, breed, ageCategory, gender, size, color, coat,
      fee, description, healthStatus, story,
      locationAddress, locationCity, locationCountry, zipCode,
      shelterContactEmail, shelterContactPhone,
      traits, photos,
    } = req.body;

    // Validare minimă
    if (!name || !type) {
      return res.status(400).json({
        success: false,
        message: 'Name and type are required.',
      });
    }

    // Folosește contact info de la user dacă nu e specificat
    const contactEmail = shelterContactEmail || userEmail;
    const contactPhone = shelterContactPhone || '';

    // Insert pet cu owner_id
    const petResult = await client.query(
      `INSERT INTO pets (
         name, type, breed, age_category, gender, size, color, coat,
         fee, description, health_status, story,
         location_address, location_city, location_country, zip_code,
         shelter_contact_email, shelter_contact_phone,
         owner_id
       ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19)
       RETURNING *`,
      [
        name, type, breed, ageCategory, gender, size, color, coat,
        fee || 0, description, healthStatus, story,
        locationAddress, locationCity, locationCountry, zipCode,
        contactEmail, contactPhone,
        userId,
      ]
    );

    const petId = petResult.rows[0].id;

    // Insert traits
    if (traits && traits.length > 0) {
      for (const trait of traits) {
        await client.query(
          'INSERT INTO pet_traits (pet_id, trait) VALUES ($1, $2)',
          [petId, trait]
        );
      }
    }

    // Insert photos
    if (photos && photos.length > 0) {
      for (let i = 0; i < photos.length; i++) {
        const photoUrl = typeof photos[i] === 'string' ? photos[i] : photos[i].url;
        await client.query(
          `INSERT INTO pet_photos (pet_id, photo_url, is_primary)
           VALUES ($1, $2, $3)`,
          [petId, photoUrl, i === 0]
        );
      }
    }

    await client.query('COMMIT');

    // Fetch pet-ul complet cu toate relațiile
    const fullPetResult = await query(
      `SELECT
        p.*,
        (SELECT json_agg(json_build_object('id', id, 'url', photo_url, 'is_primary', is_primary))
         FROM pet_photos WHERE pet_id = p.id) as photos,
        (SELECT json_agg(trait) FROM pet_traits WHERE pet_id = p.id) as traits
      FROM pets p
      WHERE p.id = $1`,
      [petId]
    );

    res.status(201).json({
      success: true,
      message: 'Pet listed successfully! It is now visible to potential adopters.',
      data: {
        pet: fullPetResult.rows[0],
      },
    });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Create pet error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while listing your pet.',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  } finally {
    client.release();
  }
};

// ========================================
// UPDATE PET - Editează animal (doar owner)
// ========================================
const updatePet = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;
    const updates = req.body;

    // Build update query
    const fieldMapping = {
      name: 'name',
      type: 'type',
      breed: 'breed',
      ageCategory: 'age_category',
      gender: 'gender',
      size: 'size',
      color: 'color',
      coat: 'coat',
      fee: 'fee',
      description: 'description',
      healthStatus: 'health_status',
      story: 'story',
      locationAddress: 'location_address',
      locationCity: 'location_city',
      locationCountry: 'location_country',
      zipCode: 'zip_code',
      shelterContactEmail: 'shelter_contact_email',
      shelterContactPhone: 'shelter_contact_phone',
      isAvailable: 'is_available',
      adoptionStatus: 'adoption_status',
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

    params.push(id);
    params.push(userId);

    const updateQuery = `
      UPDATE pets
      SET ${updateFields.join(', ')}
      WHERE id = $${paramIndex} AND owner_id = $${paramIndex + 1}
      RETURNING *
    `;

    const result = await query(updateQuery, params);

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Pet not found or you do not have permission to edit it.',
      });
    }

    res.status(200).json({
      success: true,
      message: 'Pet updated successfully!',
      data: {
        pet: result.rows[0],
      },
    });
  } catch (error) {
    console.error('Update pet error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while updating the pet.',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// ========================================
// DELETE PET - Șterge animal (doar owner)
// ========================================
const deletePet = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    // Verifică dacă există cereri de adopție aprobate
    const adoptionsCheck = await query(
      `SELECT id FROM adoptions WHERE pet_id = $1 AND status = 'approved'`,
      [id]
    );

    if (adoptionsCheck.rows.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'Cannot delete a pet that has been adopted. The adoption record must be preserved.',
      });
    }

    const result = await query(
      'DELETE FROM pets WHERE id = $1 AND owner_id = $2 RETURNING id, name',
      [id, userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Pet not found or you do not have permission to delete it.',
      });
    }

    res.status(200).json({
      success: true,
      message: `Pet "${result.rows[0].name}" has been removed from listings.`,
    });
  } catch (error) {
    console.error('Delete pet error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while deleting the pet.',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// ========================================
// ADD PET PHOTO
// ========================================
const addPetPhoto = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;
    const { url, isPrimary = false } = req.body;

    // Verifică ownership
    const petResult = await query(
      'SELECT id FROM pets WHERE id = $1 AND owner_id = $2',
      [id, userId]
    );

    if (petResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Pet not found or you do not have permission to add photos.',
      });
    }

    // Dacă setăm ca primary, deselectăm celelalte
    if (isPrimary) {
      await query(
        'UPDATE pet_photos SET is_primary = false WHERE pet_id = $1',
        [id]
      );
    }

    const result = await query(
      `INSERT INTO pet_photos (pet_id, photo_url, is_primary)
       VALUES ($1, $2, $3) RETURNING *`,
      [id, url, isPrimary]
    );

    res.status(201).json({
      success: true,
      message: 'Photo added successfully!',
      data: {
        photo: result.rows[0],
      },
    });
  } catch (error) {
    console.error('Add pet photo error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while adding the photo.',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// ========================================
// DELETE PET PHOTO
// ========================================
const deletePetPhoto = async (req, res) => {
  try {
    const { id, photoId } = req.params;
    const userId = req.user.id;

    // Verifică ownership
    const petResult = await query(
      'SELECT id FROM pets WHERE id = $1 AND owner_id = $2',
      [id, userId]
    );

    if (petResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Pet not found or you do not have permission to delete photos.',
      });
    }

    const result = await query(
      'DELETE FROM pet_photos WHERE id = $1 AND pet_id = $2 RETURNING id',
      [photoId, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Photo not found.',
      });
    }

    res.status(200).json({
      success: true,
      message: 'Photo deleted successfully.',
    });
  } catch (error) {
    console.error('Delete pet photo error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while deleting the photo.',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// ========================================
// GET SINGLE PET (owned by user)
// ========================================
const getMyPetById = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    const petQuery = `
      SELECT
        p.*,
        (SELECT json_agg(json_build_object('id', id, 'url', photo_url, 'is_primary', is_primary))
         FROM pet_photos WHERE pet_id = p.id) as photos,
        (SELECT json_agg(trait) FROM pet_traits WHERE pet_id = p.id) as traits,
        (SELECT COUNT(*) FROM favorites WHERE pet_id = p.id) as favorite_count,
        (SELECT COUNT(*) FROM adoptions WHERE pet_id = p.id) as total_applications,
        (SELECT COUNT(*) FROM adoptions WHERE pet_id = p.id AND status = 'pending') as pending_applications
      FROM pets p
      WHERE p.id = $1 AND p.owner_id = $2
    `;

    const result = await query(petQuery, [id, userId]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Pet not found or you do not have permission to view it.',
      });
    }

    res.status(200).json({
      success: true,
      data: {
        pet: result.rows[0],
      },
    });
  } catch (error) {
    console.error('Get my pet by ID error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while fetching pet details.',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// ========================================
// EXPORTS
// ========================================
module.exports = {
  getMyPets,
  getMyPetById,
  createPet,
  updatePet,
  deletePet,
  addPetPhoto,
  deletePetPhoto,
};
