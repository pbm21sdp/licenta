// src/controllers/owner-adoptions.controller.js
// Controller pentru gestionarea cererilor de adopție primite (din perspectiva owner-ului)

const { query } = require('../config/database');

// ========================================
// GET ADOPTION REQUESTS - Cereri pentru animalele mele
// ========================================
const getMyAdoptionRequests = async (req, res) => {
  try {
    const userId = req.user.id;
    const { status, petId, page = 1, limit = 20 } = req.query;

    const offset = (parseInt(page) - 1) * parseInt(limit);

    let whereConditions = [
      'p.owner_id = $1'  // Doar pentru animalele unde utilizatorul este owner
    ];
    let params = [userId];
    let paramIndex = 2;

    if (status) {
      whereConditions.push(`a.status = $${paramIndex}`);
      params.push(status);
      paramIndex++;
    }

    if (petId) {
      whereConditions.push(`a.pet_id = $${paramIndex}`);
      params.push(parseInt(petId));
      paramIndex++;
    }

    params.push(parseInt(limit));
    params.push(offset);

    const adoptionsQuery = `
      SELECT
        a.*,
        u.name as applicant_name, u.email as applicant_email, u.avatar_url as applicant_avatar,
        (SELECT photo_url FROM pet_photos WHERE pet_id = a.pet_id AND is_primary = true LIMIT 1) as pet_photo,
        (SELECT json_build_object(
          'id', sm.id,
          'scheduled_date', sm.scheduled_date,
          'scheduled_time', sm.scheduled_time,
          'location', sm.location,
          'status', sm.status
        ) FROM scheduled_meetings sm WHERE sm.adoption_id = a.id LIMIT 1) as meeting
      FROM adoptions a
      LEFT JOIN users u ON a.user_id = u.id
      LEFT JOIN pets p ON a.pet_id = p.id
      WHERE ${whereConditions.join(' AND ')}
      ORDER BY
        CASE a.status
          WHEN 'pending' THEN 1
          WHEN 'in_review' THEN 2
          ELSE 3
        END,
        a.created_at DESC
      LIMIT $${paramIndex} OFFSET $${paramIndex + 1}
    `;

    const countQuery = `
      SELECT COUNT(*) as total
      FROM adoptions a
      LEFT JOIN pets p ON a.pet_id = p.id
      WHERE ${whereConditions.join(' AND ')}
    `;

    const [adoptionsResult, countResult] = await Promise.all([
      query(adoptionsQuery, params),
      query(countQuery, params.slice(0, -2)),
    ]);

    const total = parseInt(countResult.rows[0].total);
    const totalPages = Math.ceil(total / parseInt(limit));

    // Numără cereri pe status
    const statsQuery = `
      SELECT
        COUNT(*) FILTER (WHERE a.status = 'pending') as pending_count,
        COUNT(*) FILTER (WHERE a.status = 'in_review') as in_review_count,
        COUNT(*) FILTER (WHERE a.status = 'approved') as approved_count,
        COUNT(*) FILTER (WHERE a.status = 'rejected') as rejected_count
      FROM adoptions a
      LEFT JOIN pets p ON a.pet_id = p.id
      WHERE p.owner_id = $1
    `;
    const statsResult = await query(statsQuery, [userId]);

    res.status(200).json({
      success: true,
      data: {
        applications: adoptionsResult.rows,
        stats: {
          pending: parseInt(statsResult.rows[0].pending_count),
          inReview: parseInt(statsResult.rows[0].in_review_count),
          approved: parseInt(statsResult.rows[0].approved_count),
          rejected: parseInt(statsResult.rows[0].rejected_count),
        },
        pagination: {
          currentPage: parseInt(page),
          totalPages,
          totalItems: total,
          itemsPerPage: parseInt(limit),
        },
      },
    });
  } catch (error) {
    console.error('Get my adoption requests error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while fetching adoption requests.',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// ========================================
// GET SINGLE ADOPTION REQUEST (detailed)
// ========================================
const getAdoptionRequestById = async (req, res) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;

    const adoptionQuery = `
      SELECT
        a.*,
        u.name as applicant_name, u.email as applicant_email, u.avatar_url as applicant_avatar,
        u.created_at as applicant_since,
        p.name as pet_name_current, p.type as pet_type_current,
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
        ) FROM scheduled_meetings sm WHERE sm.adoption_id = a.id LIMIT 1) as meeting,
        (SELECT COUNT(*) FROM adoptions WHERE user_id = a.user_id AND status = 'approved') as applicant_previous_adoptions
      FROM adoptions a
      LEFT JOIN users u ON a.user_id = u.id
      LEFT JOIN pets p ON a.pet_id = p.id
      WHERE a.id = $1 AND p.owner_id = $2
    `;

    const result = await query(adoptionQuery, [id, userId]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Adoption request not found or you do not have permission to view it.',
      });
    }

    res.status(200).json({
      success: true,
      data: {
        application: result.rows[0],
      },
    });
  } catch (error) {
    console.error('Get adoption request by ID error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while fetching adoption request details.',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// ========================================
// UPDATE ADOPTION STATUS - Aprobă/Respinge cerere
// ========================================
const updateAdoptionStatus = async (req, res) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;
    const { status, ownerNotes } = req.body;

    // Validare status
    const validStatuses = ['pending', 'in_review', 'approved', 'rejected'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid status. Must be one of: pending, in_review, approved, rejected.',
      });
    }

    // Verifică dacă cererea există și utilizatorul este owner-ul animalului
    const adoptionResult = await query(
      `SELECT a.*, p.owner_id, p.id as pet_id_check
       FROM adoptions a
       LEFT JOIN pets p ON a.pet_id = p.id
       WHERE a.id = $1`,
      [id]
    );

    if (adoptionResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Adoption request not found.',
      });
    }

    const adoption = adoptionResult.rows[0];

    if (adoption.owner_id !== userId) {
      return res.status(403).json({
        success: false,
        message: 'You do not have permission to update this adoption request.',
      });
    }

    // Update adoption status (folosim admin_notes pentru owner notes)
    const updateQuery = ownerNotes
      ? 'UPDATE adoptions SET status = $1, admin_notes = $2 WHERE id = $3 RETURNING *'
      : 'UPDATE adoptions SET status = $1 WHERE id = $2 RETURNING *';

    const updateParams = ownerNotes
      ? [status, ownerNotes, id]
      : [status, id];

    const result = await query(updateQuery, updateParams);

    // Update pet status based on adoption status
    if (status === 'approved') {
      await query(
        "UPDATE pets SET adoption_status = 'adopted', is_available = false WHERE id = $1",
        [adoption.pet_id]
      );

      // Respinge automat toate celelalte cereri pending pentru acest animal
      await query(
        `UPDATE adoptions SET status = 'rejected', admin_notes = 'Another application was approved by the owner.'
         WHERE pet_id = $1 AND id != $2 AND status IN ('pending', 'in_review')`,
        [adoption.pet_id, id]
      );
    } else if (status === 'rejected') {
      // Verifică dacă mai sunt alte cereri pending
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
      message: `Application ${status === 'approved' ? 'approved' : status === 'rejected' ? 'declined' : 'updated'} successfully.`,
      data: {
        application: result.rows[0],
      },
    });
  } catch (error) {
    console.error('Update adoption status error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while updating the adoption status.',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// ========================================
// SCHEDULE MEETING - Programează întâlnire cu aplicantul
// ========================================
const scheduleMeeting = async (req, res) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;
    const { scheduledDate, scheduledTime, location, notes } = req.body;

    // Validare
    if (!scheduledDate || !scheduledTime || !location) {
      return res.status(400).json({
        success: false,
        message: 'Scheduled date, time, and location are required.',
      });
    }

    // Verifică ownership
    const adoptionResult = await query(
      `SELECT a.*, p.owner_id
       FROM adoptions a
       LEFT JOIN pets p ON a.pet_id = p.id
       WHERE a.id = $1`,
      [id]
    );

    if (adoptionResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Adoption request not found.',
      });
    }

    const adoption = adoptionResult.rows[0];

    if (adoption.owner_id !== userId) {
      return res.status(403).json({
        success: false,
        message: 'You do not have permission to schedule a meeting for this adoption request.',
      });
    }

    // Verifică dacă există deja un meeting
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
      message: 'Meeting scheduled successfully! The applicant will be notified.',
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
// GET STATS - Statistici pentru owner
// ========================================
const getOwnerStats = async (req, res) => {
  try {
    const userId = req.user.id;

    const statsQuery = `
      SELECT
        (SELECT COUNT(*) FROM pets WHERE owner_id = $1) as total_pets,
        (SELECT COUNT(*) FROM pets WHERE owner_id = $1 AND is_available = true) as available_pets,
        (SELECT COUNT(*) FROM pets WHERE owner_id = $1 AND adoption_status = 'adopted') as adopted_pets,
        (SELECT COUNT(*)
         FROM adoptions a
         JOIN pets p ON a.pet_id = p.id
         WHERE p.owner_id = $1 AND a.status = 'pending') as pending_requests,
        (SELECT COUNT(*)
         FROM adoptions a
         JOIN pets p ON a.pet_id = p.id
         WHERE p.owner_id = $1) as total_requests
    `;

    const result = await query(statsQuery, [userId]);
    const stats = result.rows[0];

    res.status(200).json({
      success: true,
      data: {
        totalPets: parseInt(stats.total_pets),
        availablePets: parseInt(stats.available_pets),
        adoptedPets: parseInt(stats.adopted_pets),
        pendingRequests: parseInt(stats.pending_requests),
        totalRequests: parseInt(stats.total_requests),
      },
    });
  } catch (error) {
    console.error('Get owner stats error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while fetching statistics.',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// ========================================
// EXPORTS
// ========================================
module.exports = {
  getMyAdoptionRequests,
  getAdoptionRequestById,
  updateAdoptionStatus,
  scheduleMeeting,
  getOwnerStats,
};
