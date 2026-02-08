// src/middleware/ownership.js
// Middleware pentru verificarea proprietății resurselor

const { query } = require('../config/database');

/**
 * Middleware pentru verificarea că utilizatorul este proprietarul unui animal
 * Verifică dacă pet-ul cu ID-ul din req.params.id aparține utilizatorului autentificat
 */
const requirePetOwnership = async (req, res, next) => {
  try {
    const petId = req.params.id;
    const userId = req.user?.id;

    if (!userId) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required.',
      });
    }

    if (!petId) {
      return res.status(400).json({
        success: false,
        message: 'Pet ID is required.',
      });
    }

    // Verifică dacă pet-ul există și aparține utilizatorului
    const result = await query(
      'SELECT id, owner_id FROM pets WHERE id = $1',
      [petId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Pet not found.',
      });
    }

    const pet = result.rows[0];

    // Verifică ownership
    if (pet.owner_id !== userId) {
      return res.status(403).json({
        success: false,
        message: 'You do not have permission to modify this pet. Only the owner can perform this action.',
      });
    }

    // Atașează pet-ul la request pentru utilizare ulterioară
    req.pet = pet;
    next();
  } catch (error) {
    console.error('Pet ownership check error:', error);
    return res.status(500).json({
      success: false,
      message: 'An error occurred while verifying ownership.',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

/**
 * Middleware pentru verificarea că utilizatorul este proprietarul animalului
 * dintr-o cerere de adopție (pentru a aproba/respinge cererea)
 */
const requireAdoptionOwnership = async (req, res, next) => {
  try {
    const adoptionId = req.params.id;
    const userId = req.user?.id;

    if (!userId) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required.',
      });
    }

    if (!adoptionId) {
      return res.status(400).json({
        success: false,
        message: 'Adoption ID is required.',
      });
    }

    // Verifică dacă cererea există și dacă utilizatorul este owner-ul animalului
    const result = await query(
      `SELECT a.*, p.owner_id
       FROM adoptions a
       LEFT JOIN pets p ON a.pet_id = p.id
       WHERE a.id = $1`,
      [adoptionId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Adoption application not found.',
      });
    }

    const adoption = result.rows[0];

    // Verifică dacă utilizatorul este owner-ul animalului
    // sau dacă owner_id din adoption matches (pentru istoric)
    if (adoption.owner_id !== userId) {
      return res.status(403).json({
        success: false,
        message: 'You do not have permission to manage this adoption request. Only the pet owner can perform this action.',
      });
    }

    // Atașează adoption-ul la request pentru utilizare ulterioară
    req.adoption = adoption;
    next();
  } catch (error) {
    console.error('Adoption ownership check error:', error);
    return res.status(500).json({
      success: false,
      message: 'An error occurred while verifying ownership.',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

/**
 * Middleware opțional pentru verificare ownership
 * Nu blochează dacă utilizatorul nu este owner, dar adaugă un flag
 */
const checkPetOwnership = async (req, res, next) => {
  try {
    const petId = req.params.id;
    const userId = req.user?.id;

    req.isOwner = false;

    if (!userId || !petId) {
      return next();
    }

    const result = await query(
      'SELECT owner_id FROM pets WHERE id = $1',
      [petId]
    );

    if (result.rows.length > 0 && result.rows[0].owner_id === userId) {
      req.isOwner = true;
    }

    next();
  } catch (error) {
    // În caz de eroare, continuă fără flag-ul de ownership
    console.error('Optional ownership check error:', error);
    next();
  }
};

module.exports = {
  requirePetOwnership,
  requireAdoptionOwnership,
  checkPetOwnership,
};
