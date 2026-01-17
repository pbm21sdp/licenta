// src/controllers/admin.controller.js
const { query, getClient } = require('../config/database');

// ========================================
// PET MANAGEMENT
// ========================================

// GET ALL PETS (admin view with all statuses)
const getAllPets = async (req, res) => {
  try {
    const { status, type, page = 1, limit = 20, search } = req.query;

    const offset = (parseInt(page) - 1) * parseInt(limit);

    let whereConditions = [];
    let params = [];
    let paramIndex = 1;

    if (status) {
      whereConditions.push(`p.adoption_status = $${paramIndex}`);
      params.push(status);
      paramIndex++;
    }

    if (type) {
      whereConditions.push(`p.type = $${paramIndex}`);
      params.push(type);
      paramIndex++;
    }

    if (search) {
      whereConditions.push(`(p.name ILIKE $${paramIndex} OR p.breed ILIKE $${paramIndex})`);
      params.push(`%${search}%`);
      paramIndex++;
    }

    const whereClause = whereConditions.length > 0
      ? `WHERE ${whereConditions.join(' AND ')}`
      : '';

    params.push(parseInt(limit));
    params.push(offset);

    const petsQuery = `
      SELECT
        p.*,
        (SELECT photo_url FROM pet_photos WHERE pet_id = p.id AND is_primary = true LIMIT 1) as primary_photo,
        (SELECT COUNT(*) FROM favorites WHERE pet_id = p.id) as favorite_count,
        (SELECT COUNT(*) FROM adoptions WHERE pet_id = p.id) as application_count
      FROM pets p
      ${whereClause}
      ORDER BY p.created_at DESC
      LIMIT $${paramIndex} OFFSET $${paramIndex + 1}
    `;

    const countQuery = `SELECT COUNT(*) as total FROM pets p ${whereClause}`;

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
    console.error('Admin get all pets error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while fetching pets.',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// CREATE NEW PET
const createPet = async (req, res) => {
  const client = await getClient();

  try {
    await client.query('BEGIN');

    const {
      name, type, breed, ageCategory, gender, size, color, coat,
      fee, description, healthStatus, story,
      locationAddress, locationCity, locationCountry, zipCode,
      shelterContactEmail, shelterContactPhone,
      traits, photos,
    } = req.body;

    // Insert pet
    const petResult = await client.query(
      `INSERT INTO pets (
         name, type, breed, age_category, gender, size, color, coat,
         fee, description, health_status, story,
         location_address, location_city, location_country, zip_code,
         shelter_contact_email, shelter_contact_phone
       ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18)
       RETURNING *`,
      [
        name, type, breed, ageCategory, gender, size, color, coat,
        fee || 0, description, healthStatus, story,
        locationAddress, locationCity, locationCountry, zipCode,
        shelterContactEmail, shelterContactPhone,
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
        await client.query(
          `INSERT INTO pet_photos (pet_id, photo_url, is_primary)
           VALUES ($1, $2, $3)`,
          [petId, photos[i].url, i === 0]
        );
      }
    }

    await client.query('COMMIT');

    res.status(201).json({
      success: true,
      message: 'Pet created successfully!',
      data: {
        pet: petResult.rows[0],
      },
    });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Create pet error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while creating the pet.',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  } finally {
    client.release();
  }
};

// UPDATE PET
const updatePet = async (req, res) => {
  try {
    const { id } = req.params;
    const updates = req.body;

    // Check if pet exists
    const existingResult = await query('SELECT id FROM pets WHERE id = $1', [id]);
    if (existingResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Pet not found.',
      });
    }

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

    const updateQuery = `
      UPDATE pets
      SET ${updateFields.join(', ')}
      WHERE id = $${paramIndex}
      RETURNING *
    `;

    const result = await query(updateQuery, params);

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

// DELETE PET
const deletePet = async (req, res) => {
  try {
    const { id } = req.params;

    const result = await query(
      'DELETE FROM pets WHERE id = $1 RETURNING id, name',
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Pet not found.',
      });
    }

    res.status(200).json({
      success: true,
      message: `Pet "${result.rows[0].name}" deleted successfully.`,
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

// ADD PET PHOTO
const addPetPhoto = async (req, res) => {
  try {
    const { id } = req.params;
    const { url, isPrimary = false } = req.body;

    // Check if pet exists
    const petResult = await query('SELECT id FROM pets WHERE id = $1', [id]);
    if (petResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Pet not found.',
      });
    }

    // If setting as primary, unset other primary photos
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

// DELETE PET PHOTO
const deletePetPhoto = async (req, res) => {
  try {
    const { id, photoId } = req.params;

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
// ADOPTION MANAGEMENT
// ========================================

// GET ALL ADOPTIONS
const getAllAdoptions = async (req, res) => {
  try {
    const { status, page = 1, limit = 20 } = req.query;

    const offset = (parseInt(page) - 1) * parseInt(limit);

    let whereConditions = [];
    let params = [];
    let paramIndex = 1;

    if (status) {
      whereConditions.push(`a.status = $${paramIndex}`);
      params.push(status);
      paramIndex++;
    }

    const whereClause = whereConditions.length > 0
      ? `WHERE ${whereConditions.join(' AND ')}`
      : '';

    params.push(parseInt(limit));
    params.push(offset);

    const adoptionsQuery = `
      SELECT
        a.*,
        u.name as user_name, u.email as user_email,
        (SELECT photo_url FROM pet_photos WHERE pet_id = a.pet_id AND is_primary = true LIMIT 1) as pet_photo
      FROM adoptions a
      LEFT JOIN users u ON a.user_id = u.id
      ${whereClause}
      ORDER BY a.created_at DESC
      LIMIT $${paramIndex} OFFSET $${paramIndex + 1}
    `;

    const countQuery = `SELECT COUNT(*) as total FROM adoptions a ${whereClause}`;

    const [adoptionsResult, countResult] = await Promise.all([
      query(adoptionsQuery, params),
      query(countQuery, params.slice(0, -2)),
    ]);

    const total = parseInt(countResult.rows[0].total);
    const totalPages = Math.ceil(total / parseInt(limit));

    res.status(200).json({
      success: true,
      data: {
        applications: adoptionsResult.rows,
        pagination: {
          currentPage: parseInt(page),
          totalPages,
          totalItems: total,
          itemsPerPage: parseInt(limit),
        },
      },
    });
  } catch (error) {
    console.error('Admin get all adoptions error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while fetching applications.',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// GET SINGLE ADOPTION (admin view with full details)
const getAdoptionDetails = async (req, res) => {
  try {
    const { id } = req.params;

    const adoptionQuery = `
      SELECT
        a.*,
        u.name as user_name, u.email as user_email, u.created_at as user_since,
        (SELECT json_agg(json_build_object('id', id, 'url', photo_url, 'is_primary', is_primary))
         FROM pet_photos WHERE pet_id = a.pet_id) as pet_photos,
        (SELECT json_build_object(
          'id', sm.id,
          'scheduled_date', sm.scheduled_date,
          'scheduled_time', sm.scheduled_time,
          'location', sm.location,
          'status', sm.status,
          'notes', sm.notes,
          'admin_message', sm.admin_message
        ) FROM scheduled_meetings sm WHERE sm.adoption_id = a.id LIMIT 1) as meeting
      FROM adoptions a
      LEFT JOIN users u ON a.user_id = u.id
      WHERE a.id = $1
    `;

    const result = await query(adoptionQuery, [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Application not found.',
      });
    }

    res.status(200).json({
      success: true,
      data: {
        application: result.rows[0],
      },
    });
  } catch (error) {
    console.error('Admin get adoption details error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while fetching application details.',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// UPDATE ADOPTION STATUS
const updateAdoptionStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status, adminNotes } = req.body;

    // Validate status
    const validStatuses = ['pending', 'in_review', 'approved', 'rejected'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid status. Must be one of: pending, in_review, approved, rejected.',
      });
    }

    // Get adoption details
    const adoptionResult = await query(
      'SELECT * FROM adoptions WHERE id = $1',
      [id]
    );

    if (adoptionResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Application not found.',
      });
    }

    const adoption = adoptionResult.rows[0];

    // Update adoption status
    const updateQuery = adminNotes
      ? 'UPDATE adoptions SET status = $1, admin_notes = $2 WHERE id = $3 RETURNING *'
      : 'UPDATE adoptions SET status = $1 WHERE id = $2 RETURNING *';

    const updateParams = adminNotes
      ? [status, adminNotes, id]
      : [status, id];

    const result = await query(updateQuery, updateParams);

    // Update pet status based on adoption status
    if (status === 'approved') {
      await query(
        "UPDATE pets SET adoption_status = 'adopted', is_available = false WHERE id = $1",
        [adoption.pet_id]
      );

      // Reject all other pending applications for this pet
      await query(
        `UPDATE adoptions SET status = 'rejected', admin_notes = 'Another application was approved.'
         WHERE pet_id = $1 AND id != $2 AND status IN ('pending', 'in_review')`,
        [adoption.pet_id, id]
      );
    } else if (status === 'rejected') {
      // Check if there are other pending applications
      const otherApps = await query(
        `SELECT id FROM adoptions WHERE pet_id = $1 AND status IN ('pending', 'in_review')`,
        [adoption.pet_id]
      );

      if (otherApps.rows.length === 0) {
        await query(
          "UPDATE pets SET adoption_status = 'available', is_available = true WHERE id = $1",
          [adoption.pet_id]
        );
      }
    } else if (status === 'in_review') {
      await query(
        "UPDATE pets SET adoption_status = 'in_review' WHERE id = $1",
        [adoption.pet_id]
      );
    }

    res.status(200).json({
      success: true,
      message: `Application status updated to "${status}".`,
      data: {
        application: result.rows[0],
      },
    });
  } catch (error) {
    console.error('Update adoption status error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while updating the status.',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// SCHEDULE MEETING
const scheduleMeeting = async (req, res) => {
  try {
    const { id } = req.params;
    const { scheduledDate, scheduledTime, location, notes } = req.body;

    // Get adoption details
    const adoptionResult = await query(
      'SELECT * FROM adoptions WHERE id = $1',
      [id]
    );

    if (adoptionResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Application not found.',
      });
    }

    const adoption = adoptionResult.rows[0];

    // Check if meeting already exists
    const existingMeeting = await query(
      'SELECT id FROM scheduled_meetings WHERE adoption_id = $1',
      [id]
    );

    let result;

    if (existingMeeting.rows.length > 0) {
      // Update existing meeting
      result = await query(
        `UPDATE scheduled_meetings
         SET scheduled_date = $1, scheduled_time = $2, location = $3, notes = $4, status = 'pending'
         WHERE adoption_id = $5
         RETURNING *`,
        [scheduledDate, scheduledTime, location, notes, id]
      );
    } else {
      // Create new meeting
      result = await query(
        `INSERT INTO scheduled_meetings (
           adoption_id, user_id, pet_id, pet_name,
           scheduled_date, scheduled_time, location, notes
         ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
         RETURNING *`,
        [
          id, adoption.user_id, adoption.pet_id, adoption.pet_name,
          scheduledDate, scheduledTime, location, notes,
        ]
      );
    }

    // Update adoption status to in_review if pending
    if (adoption.status === 'pending') {
      await query(
        "UPDATE adoptions SET status = 'in_review' WHERE id = $1",
        [id]
      );
    }

    res.status(201).json({
      success: true,
      message: 'Meeting scheduled successfully!',
      data: {
        meeting: result.rows[0],
      },
    });
  } catch (error) {
    console.error('Schedule meeting error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while scheduling the meeting.',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// ========================================
// DASHBOARD STATS
// ========================================
const getDashboardStats = async (req, res) => {
  try {
    const statsQueries = await Promise.all([
      query("SELECT COUNT(*) as total FROM pets WHERE is_available = true"),
      query("SELECT COUNT(*) as total FROM pets WHERE adoption_status = 'adopted'"),
      query("SELECT COUNT(*) as total FROM adoptions WHERE status = 'pending'"),
      query("SELECT COUNT(*) as total FROM users WHERE is_admin = false"),
      query(`
        SELECT type, COUNT(*) as count
        FROM pets
        GROUP BY type
        ORDER BY count DESC
      `),
      query(`
        SELECT status, COUNT(*) as count
        FROM adoptions
        GROUP BY status
      `),
    ]);

    res.status(200).json({
      success: true,
      data: {
        availablePets: parseInt(statsQueries[0].rows[0].total),
        adoptedPets: parseInt(statsQueries[1].rows[0].total),
        pendingApplications: parseInt(statsQueries[2].rows[0].total),
        totalUsers: parseInt(statsQueries[3].rows[0].total),
        petsByType: statsQueries[4].rows,
        applicationsByStatus: statsQueries[5].rows,
      },
    });
  } catch (error) {
    console.error('Get dashboard stats error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while fetching dashboard stats.',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// ========================================
// EXPORTS
// ========================================
module.exports = {
  // Pet management
  getAllPets,
  createPet,
  updatePet,
  deletePet,
  addPetPhoto,
  deletePetPhoto,
  // Adoption management
  getAllAdoptions,
  getAdoptionDetails,
  updateAdoptionStatus,
  scheduleMeeting,
  // Dashboard
  getDashboardStats,
};
