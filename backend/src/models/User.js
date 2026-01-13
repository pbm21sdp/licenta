// src/models/User.js
const { query } = require('../config/database');
const bcrypt = require('bcryptjs');
const crypto = require('crypto');

class User {
  /**
   * Create a new user
   * @param {Object} userData - User data
   * @returns {Object} Created user
   */
  static async create(userData) {
    const {
      email,
      password,
      name,
      isAdmin = false,
      isVerified = false,
    } = userData;

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Generate verification token
    const verificationToken = crypto.randomBytes(32).toString('hex');
    const verificationExpires = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24 hours

    const result = await query(
      `INSERT INTO users 
       (email, password, name, is_admin, is_verified, verification_token, verification_token_expires_at) 
       VALUES ($1, $2, $3, $4, $5, $6, $7) 
       RETURNING id, email, name, is_verified, is_admin, created_at`,
      [
        email,
        hashedPassword,
        name,
        isAdmin,
        isVerified,
        verificationToken,
        verificationExpires,
      ]
    );

    return {
      user: result.rows[0],
      verificationToken,
    };
  }

  /**
   * Find user by email
   * @param {string} email - User email
   * @returns {Object|null} User object or null
   */
  static async findByEmail(email) {
    const result = await query(
      'SELECT * FROM users WHERE email = $1 AND deleted_at IS NULL',
      [email]
    );
    return result.rows[0] || null;
  }

  /**
   * Find user by ID
   * @param {number} id - User ID
   * @returns {Object|null} User object or null
   */
  static async findById(id) {
    const result = await query(
      'SELECT id, email, name, avatar_url, is_verified, is_admin, last_login, created_at, updated_at FROM users WHERE id = $1 AND deleted_at IS NULL',
      [id]
    );
    return result.rows[0] || null;
  }

  /**
   * Verify password
   * @param {string} plainPassword - Plain text password
   * @param {string} hashedPassword - Hashed password from database
   * @returns {boolean} True if password matches
   */
  static async verifyPassword(plainPassword, hashedPassword) {
    return await bcrypt.compare(plainPassword, hashedPassword);
  }

  /**
   * Update last login timestamp
   * @param {number} userId - User ID
   */
  static async updateLastLogin(userId) {
    await query(
      'UPDATE users SET last_login = CURRENT_TIMESTAMP WHERE id = $1',
      [userId]
    );
  }

  /**
   * Verify email with token
   * @param {string} token - Verification token
   * @returns {Object|null} User object or null
   */
  static async verifyEmail(token) {
    const result = await query(
      `UPDATE users 
       SET is_verified = true, 
           verification_token = NULL, 
           verification_token_expires_at = NULL 
       WHERE verification_token = $1 
         AND verification_token_expires_at > CURRENT_TIMESTAMP 
         AND deleted_at IS NULL
       RETURNING id, email, name, is_verified, is_admin`,
      [token]
    );
    return result.rows[0] || null;
  }

  /**
   * Generate password reset token
   * @param {string} email - User email
   * @returns {string|null} Reset token or null
   */
  static async generateResetToken(email) {
    const resetToken = crypto.randomBytes(32).toString('hex');
    const resetExpires = new Date(Date.now() + 60 * 60 * 1000); // 1 hour

    const result = await query(
      `UPDATE users 
       SET reset_password_token = $1, 
           reset_password_expires_at = $2 
       WHERE email = $3 AND deleted_at IS NULL
       RETURNING id, email, name`,
      [resetToken, resetExpires, email]
    );

    if (result.rows.length === 0) {
      return null;
    }

    return { token: resetToken, user: result.rows[0] };
  }

  /**
   * Reset password with token
   * @param {string} token - Reset token
   * @param {string} newPassword - New password
   * @returns {Object|null} User object or null
   */
  static async resetPassword(token, newPassword) {
    // Hash new password
    const hashedPassword = await bcrypt.hash(newPassword, 10);

    const result = await query(
      `UPDATE users 
       SET password = $1, 
           reset_password_token = NULL, 
           reset_password_expires_at = NULL 
       WHERE reset_password_token = $2 
         AND reset_password_expires_at > CURRENT_TIMESTAMP 
         AND deleted_at IS NULL
       RETURNING id, email, name, is_verified, is_admin`,
      [hashedPassword, token]
    );

    return result.rows[0] || null;
  }

  /**
   * Update user profile
   * @param {number} userId - User ID
   * @param {Object} updates - Fields to update
   * @returns {Object} Updated user
   */
  static async updateProfile(userId, updates) {
    const allowedFields = ['name', 'avatar_url'];
    const fields = [];
    const values = [];
    let paramIndex = 1;

    Object.keys(updates).forEach((key) => {
      if (allowedFields.includes(key)) {
        fields.push(`${key} = $${paramIndex}`);
        values.push(updates[key]);
        paramIndex++;
      }
    });

    if (fields.length === 0) {
      throw new Error('No valid fields to update');
    }

    values.push(userId);
    const result = await query(
      `UPDATE users 
       SET ${fields.join(', ')} 
       WHERE id = $${paramIndex} AND deleted_at IS NULL
       RETURNING id, email, name, avatar_url, is_verified, is_admin`,
      values
    );

    return result.rows[0];
  }

  /**
   * Change password
   * @param {number} userId - User ID
   * @param {string} oldPassword - Current password
   * @param {string} newPassword - New password
   * @returns {boolean} Success status
   */
  static async changePassword(userId, oldPassword, newPassword) {
    // Get user with password
    const userResult = await query(
      'SELECT password FROM users WHERE id = $1 AND deleted_at IS NULL',
      [userId]
    );

    if (userResult.rows.length === 0) {
      throw new Error('User not found');
    }

    // Verify old password
    const isValid = await this.verifyPassword(
      oldPassword,
      userResult.rows[0].password
    );
    if (!isValid) {
      throw new Error('Current password is incorrect');
    }

    // Hash new password
    const hashedPassword = await bcrypt.hash(newPassword, 10);

    // Update password
    await query('UPDATE users SET password = $1 WHERE id = $2', [
      hashedPassword,
      userId,
    ]);

    return true;
  }

  /**
   * Soft delete user (GDPR compliant)
   * @param {number} userId - User ID
   * @returns {boolean} Success status
   */
  static async softDelete(userId) {
    await query(
      'UPDATE users SET deleted_at = CURRENT_TIMESTAMP WHERE id = $1',
      [userId]
    );
    return true;
  }

  /**
   * Count admin users
   * @returns {number} Number of admin users
   */
  static async countAdmins() {
    const result = await query(
      'SELECT COUNT(*) FROM users WHERE is_admin = true AND deleted_at IS NULL'
    );
    return parseInt(result.rows[0].count);
  }

  /**
   * Enable/disable MFA for user
   * @param {number} userId - User ID
   * @param {string} secret - MFA secret
   * @returns {Object} Updated user
   */
  static async enableMFA(userId, secret) {
    const result = await query(
      `UPDATE users 
       SET mfa_secret = $1, mfa_enabled = true 
       WHERE id = $2 AND deleted_at IS NULL
       RETURNING id, email, name, mfa_enabled`,
      [secret, userId]
    );
    return result.rows[0];
  }

  /**
   * Disable MFA for user
   * @param {number} userId - User ID
   * @returns {Object} Updated user
   */
  static async disableMFA(userId) {
    const result = await query(
      `UPDATE users 
       SET mfa_secret = NULL, mfa_enabled = false 
       WHERE id = $1 AND deleted_at IS NULL
       RETURNING id, email, name, mfa_enabled`,
      [userId]
    );
    return result.rows[0];
  }

  /**
   * Get MFA secret for user
   * @param {number} userId - User ID
   * @returns {string|null} MFA secret or null
   */
  static async getMFASecret(userId) {
    const result = await query(
      'SELECT mfa_secret FROM users WHERE id = $1 AND deleted_at IS NULL',
      [userId]
    );
    return result.rows[0]?.mfa_secret || null;
  }
}

module.exports = User;