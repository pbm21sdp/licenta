// src/controllers/adoption.controller.js
const { query } = require('../config/database');

// ========================================
// GET USER'S ADOPTION APPLICATIONS
// ========================================
const getMyAdoptions = async (req, res) => {
  try {
    const userId = req.user.id;
    const { status, page = 1, limit = 10 } = req.query;

    const offset = (parseInt(page) - 1) * parseInt(limit);

    let whereConditions = ['a.user_id = $1'];
    let params = [userId];
    let paramIndex = 2;

    if (status) {
      whereConditions.push(`a.status = $${paramIndex}`);
      params.push(status);
      paramIndex++;
    }

    params.push(parseInt(limit));
    params.push(offset);

    const adoptionsQuery = `
      SELECT
        a.id, a.pet_id, a.pet_name, a.pet_type, a.pet_breed,
        a.status, a.application_date, a.created_at, a.updated_at,
        (SELECT photo_url FROM pet_photos WHERE pet_id = a.pet_id AND is_primary = true LIMIT 1) as pet_photo,
        (SELECT json_build_object(
          'id', sm.id,
          'scheduled_date', sm.scheduled_date,
          'scheduled_time', sm.scheduled_time,
          'location', sm.location,
          'status', sm.status
        ) FROM scheduled_meetings sm WHERE sm.adoption_id = a.id LIMIT 1) as meeting
      FROM adoptions a
      WHERE ${whereConditions.join(' AND ')}
      ORDER BY a.created_at DESC
      LIMIT $${paramIndex} OFFSET $${paramIndex + 1}
    `;

    const countQuery = `
      SELECT COUNT(*) as total
      FROM adoptions a
      WHERE ${whereConditions.join(' AND ')}
    `;

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
    console.error('Get my adoptions error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while fetching your applications.',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// ========================================
// GET SINGLE ADOPTION APPLICATION
// ========================================
const getAdoptionById = async (req, res) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;

    const adoptionQuery = `
      SELECT a.*,
        (SELECT photo_url FROM pet_photos WHERE pet_id = a.pet_id AND is_primary = true LIMIT 1) as pet_photo,
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
      WHERE a.id = $1 AND a.user_id = $2
    `;

    const result = await query(adoptionQuery, [id, userId]);

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
    console.error('Get adoption by ID error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while fetching the application.',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// ========================================
// SUBMIT ADOPTION APPLICATION
// ========================================
const createAdoption = async (req, res) => {
  try {
    const userId = req.user.id;
    const {
      petId,
      fullName,
      email,
      phone,
      address,
      city,
      postalCode,
      housingType,
      livingArrangement,
      hasYard,
      hasChildren,
      children,
      hasOtherPets,
      otherPets,
      otherPetsDetails,
      previousPetExperience,
      adoptionReason,
      message,
    } = req.body;

    // Check if pet exists and is available
    const petResult = await query(
      'SELECT id, name, type, breed, is_available, adoption_status FROM pets WHERE id = $1',
      [petId]
    );

    if (petResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Pet not found.',
      });
    }

    const pet = petResult.rows[0];

    if (!pet.is_available || pet.adoption_status !== 'available') {
      return res.status(400).json({
        success: false,
        message: 'This pet is no longer available for adoption.',
      });
    }

    // Check if user already has a pending application for this pet
    const existingApplication = await query(
      `SELECT id FROM adoptions
       WHERE user_id = $1 AND pet_id = $2 AND status IN ('pending', 'in_review')`,
      [userId, petId]
    );

    if (existingApplication.rows.length > 0) {
      return res.status(409).json({
        success: false,
        message: 'You already have an active application for this pet.',
      });
    }

    // Create adoption application
    const insertQuery = `
      INSERT INTO adoptions (
        user_id, pet_id, pet_name, pet_type, pet_breed,
        full_name, email, phone, address, city, postal_code,
        housing_type, living_arrangement, has_yard,
        has_children, children, has_other_pets, other_pets, other_pets_details,
        previous_pet_experience, adoption_reason, message, status
      ) VALUES (
        $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, 'pending'
      ) RETURNING *
    `;

    const result = await query(insertQuery, [
      userId, petId, pet.name, pet.type, pet.breed,
      fullName, email, phone, address, city, postalCode,
      housingType, livingArrangement, hasYard,
      hasChildren, children, hasOtherPets, otherPets, otherPetsDetails,
      previousPetExperience, adoptionReason, message,
    ]);

    // Update pet status to pending
    await query(
      "UPDATE pets SET adoption_status = 'pending' WHERE id = $1",
      [petId]
    );

    res.status(201).json({
      success: true,
      message: 'Adoption application submitted successfully! We will review your application and contact you soon.',
      data: {
        application: {
          id: result.rows[0].id,
          petName: pet.name,
          status: 'pending',
          applicationDate: result.rows[0].application_date,
        },
      },
    });
  } catch (error) {
    console.error('Create adoption error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while submitting your application.',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// ========================================
// UPDATE ADOPTION APPLICATION (if still pending)
// ========================================
const updateAdoption = async (req, res) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;
    const updates = req.body;

    // Check if application exists and belongs to user
    const existingResult = await query(
      'SELECT * FROM adoptions WHERE id = $1 AND user_id = $2',
      [id, userId]
    );

    if (existingResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Application not found.',
      });
    }

    const application = existingResult.rows[0];

    // Only allow updates if status is pending
    if (application.status !== 'pending') {
      return res.status(400).json({
        success: false,
        message: 'Cannot update application. It is no longer in pending status.',
      });
    }

    // Build update query dynamically
    const allowedFields = [
      'full_name', 'phone', 'address', 'city', 'postal_code',
      'housing_type', 'living_arrangement', 'has_yard',
      'has_children', 'children', 'has_other_pets', 'other_pets',
      'other_pets_details', 'previous_pet_experience', 'adoption_reason', 'message', 'notes',
    ];

    const updateFields = [];
    const params = [];
    let paramIndex = 1;

    for (const [key, value] of Object.entries(updates)) {
      const snakeKey = key.replace(/[A-Z]/g, letter => `_${letter.toLowerCase()}`);
      if (allowedFields.includes(snakeKey)) {
        updateFields.push(`${snakeKey} = $${paramIndex}`);
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
      UPDATE adoptions
      SET ${updateFields.join(', ')}
      WHERE id = $${paramIndex}
      RETURNING *
    `;

    const result = await query(updateQuery, params);

    res.status(200).json({
      success: true,
      message: 'Application updated successfully.',
      data: {
        application: result.rows[0],
      },
    });
  } catch (error) {
    console.error('Update adoption error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while updating your application.',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// ========================================
// CANCEL/WITHDRAW ADOPTION APPLICATION
// ========================================
const cancelAdoption = async (req, res) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;

    // Check if application exists and belongs to user
    const existingResult = await query(
      'SELECT * FROM adoptions WHERE id = $1 AND user_id = $2',
      [id, userId]
    );

    if (existingResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Application not found.',
      });
    }

    const application = existingResult.rows[0];

    // Only allow cancellation if not already approved
    if (application.status === 'approved') {
      return res.status(400).json({
        success: false,
        message: 'Cannot cancel an approved application. Please contact support.',
      });
    }

    // Delete the application
    await query('DELETE FROM adoptions WHERE id = $1', [id]);

    // Reset pet status if this was the only pending application
    const otherApplications = await query(
      `SELECT id FROM adoptions WHERE pet_id = $1 AND status IN ('pending', 'in_review')`,
      [application.pet_id]
    );

    if (otherApplications.rows.length === 0) {
      await query(
        "UPDATE pets SET adoption_status = 'available' WHERE id = $1",
        [application.pet_id]
      );
    }

    res.status(200).json({
      success: true,
      message: 'Application cancelled successfully.',
    });
  } catch (error) {
    console.error('Cancel adoption error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while cancelling your application.',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// ========================================
// EXPORTS
// ========================================
module.exports = {
  getMyAdoptions,
  getAdoptionById,
  createAdoption,
  updateAdoption,
  cancelAdoption,
};
