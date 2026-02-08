// src/controllers/auth.controller.js
const User = require('../models/User');
const { generateTokens, verifyRefreshToken } = require('../utils/jwt');
const {
  sendVerificationEmail,
  sendPasswordResetEmail,
  sendWelcomeEmail,
} = require('../config/email');
const speakeasy = require('speakeasy');
const QRCode = require('qrcode');
const crypto = require('crypto');
const { query } = require('../config/database');

// ========================================
// REGISTER
// ========================================
const register = async (req, res) => {
  try {
    const { email, password, name } = req.body;

    const existingUser = await User.findByEmail(email);
    if (existingUser) {
      return res.status(409).json({
        success: false,
        message: 'A user with this email already exists.',
      });
    }

    const adminCount = await User.countAdmins();
    const isFirstAdmin = adminCount === 0;

    const { user, verificationToken } = await User.create({
      email,
      password,
      name,
      isAdmin: isFirstAdmin,
      isVerified: false,
    });

    await sendVerificationEmail(email, name, verificationToken);
    const tokens = generateTokens(user);

    res.status(201).json({
      success: true,
      message: isFirstAdmin
        ? 'First admin account created successfully! Please verify your email.'
        : 'Registration successful! Please check your email to verify your account.',
      data: {
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          isVerified: user.is_verified,
          isAdmin: user.is_admin,
        },
        ...tokens,
      },
    });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred during registration. Please try again.',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// ========================================
// REGISTER ADMIN
// ========================================
const registerAdmin = async (req, res) => {
  try {
    const { email, password, name, adminSecretKey } = req.body;

    if (adminSecretKey !== process.env.ADMIN_SECRET_KEY) {
      return res.status(403).json({
        success: false,
        message: 'Invalid admin secret key. Access denied.',
      });
    }

    const existingUser = await User.findByEmail(email);
    if (existingUser) {
      return res.status(409).json({
        success: false,
        message: 'A user with this email already exists.',
      });
    }

    const { user } = await User.create({
      email,
      password,
      name,
      isAdmin: true,
      isVerified: true,
    });

    const tokens = generateTokens(user);

    res.status(201).json({
      success: true,
      message: 'Admin account created successfully!',
      data: {
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          isVerified: user.is_verified,
          isAdmin: user.is_admin,
        },
        ...tokens,
      },
    });
  } catch (error) {
    console.error('Admin registration error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred during admin registration. Please try again.',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// ========================================
// LOGIN
// ========================================
const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    const user = await User.findByEmail(email);
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password.',
      });
    }

    if (user.password.startsWith('oauth_')) {
      return res.status(401).json({
        success: false,
        message: 'This account was created using social login. Please use the appropriate social login button.',
      });
    }

    const isPasswordValid = await User.verifyPassword(password, user.password);
    if (!isPasswordValid) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password.',
      });
    }

    if (user.mfa_enabled && user.mfa_secret) {
      return res.status(200).json({
        success: true,
        requiresMFA: true,
        message: 'MFA verification required.',
        data: {
          userId: user.id,
          email: user.email,
        },
      });
    }

    await User.updateLastLogin(user.id);
    const tokens = generateTokens(user);

    res.status(200).json({
      success: true,
      message: 'Login successful!',
      data: {
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          isVerified: user.is_verified,
          isAdmin: user.is_admin,
        },
        ...tokens,
      },
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred during login. Please try again.',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// ========================================
// VERIFY EMAIL
// ========================================
const verifyEmail = async (req, res) => {
  try {
    const { token } = req.body;

    const user = await User.verifyEmail(token);
    if (!user) {
      return res.status(400).json({
        success: false,
        message: 'Invalid or expired verification token.',
      });
    }

    await sendWelcomeEmail(user.email, user.name);

    res.status(200).json({
      success: true,
      message: 'Email verified successfully! Your account is now active.',
      data: {
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          isVerified: user.is_verified,
          isAdmin: user.is_admin,
        },
      },
    });
  } catch (error) {
    console.error('Email verification error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred during email verification. Please try again.',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// ========================================
// RESEND VERIFICATION
// ========================================
const resendVerification = async (req, res) => {
  try {
    const { email } = req.body;

    const user = await User.findByEmail(email);
    
    if (!user) {
      return res.status(200).json({
        success: true,
        message: 'If an account with this email exists, a verification email has been sent.',
      });
    }

    if (user.is_verified) {
      return res.status(400).json({
        success: false,
        message: 'This email is already verified.',
      });
    }

    const verificationToken = crypto.randomBytes(32).toString('hex');
    const verificationExpires = new Date(Date.now() + 24 * 60 * 60 * 1000);

    await query(
      `UPDATE users 
       SET verification_token = $1, verification_token_expires_at = $2 
       WHERE id = $3`,
      [verificationToken, verificationExpires, user.id]
    );

    await sendVerificationEmail(email, user.name, verificationToken);

    res.status(200).json({
      success: true,
      message: 'Verification email sent successfully! Please check your inbox.',
    });
  } catch (error) {
    console.error('Resend verification error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred. Please try again.',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// ========================================
// FORGOT PASSWORD
// ========================================
const forgotPassword = async (req, res) => {
  try {
    const { email } = req.body;

    const result = await User.generateResetToken(email);

    if (!result) {
      return res.status(200).json({
        success: true,
        message: 'If an account with this email exists, a password reset link has been sent.',
      });
    }

    await sendPasswordResetEmail(email, result.user.name, result.token);

    res.status(200).json({
      success: true,
      message: 'Password reset link sent successfully! Please check your email.',
    });
  } catch (error) {
    console.error('Forgot password error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred. Please try again.',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// ========================================
// RESET PASSWORD
// ========================================
const resetPassword = async (req, res) => {
  try {
    const { token, password } = req.body;

    const user = await User.resetPassword(token, password);

    if (!user) {
      return res.status(400).json({
        success: false,
        message: 'Invalid or expired reset token.',
      });
    }

    res.status(200).json({
      success: true,
      message: 'Password reset successful! You can now login with your new password.',
    });
  } catch (error) {
    console.error('Reset password error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred during password reset. Please try again.',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// ========================================
// CHANGE PASSWORD
// ========================================
const changePassword = async (req, res) => {
  try {
    const { oldPassword, newPassword } = req.body;
    const userId = req.user.id;

    await User.changePassword(userId, oldPassword, newPassword);

    res.status(200).json({
      success: true,
      message: 'Password changed successfully!',
    });
  } catch (error) {
    console.error('Change password error:', error);
    
    if (error.message === 'Current password is incorrect') {
      return res.status(400).json({
        success: false,
        message: error.message,
      });
    }

    res.status(500).json({
      success: false,
      message: 'An error occurred during password change. Please try again.',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// ========================================
// REFRESH TOKEN
// ========================================
const refreshToken = async (req, res) => {
  try {
    const { refreshToken } = req.body;

    const decoded = verifyRefreshToken(refreshToken);

    const user = await User.findById(decoded.id);
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'User not found. Token may be invalid.',
      });
    }

    const tokens = generateTokens(user);

    res.status(200).json({
      success: true,
      message: 'Token refreshed successfully!',
      data: tokens,
    });
  } catch (error) {
    console.error('Refresh token error:', error);
    res.status(401).json({
      success: false,
      message: 'Invalid or expired refresh token. Please login again.',
    });
  }
};

// ========================================
// GET CURRENT USER
// ========================================
const getCurrentUser = async (req, res) => {
  try {
    const user = await User.findById(req.user.id);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found.',
      });
    }

    res.status(200).json({
      success: true,
      data: {
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          avatar_url: user.avatar_url,
          isVerified: user.is_verified,
          isAdmin: user.is_admin,
          mfaEnabled: user.mfa_enabled || false,
          lastLogin: user.last_login,
          createdAt: user.created_at,
        },
      },
    });
  } catch (error) {
    console.error('Get current user error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred. Please try again.',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// ========================================
// UPDATE PROFILE
// ========================================
const updateProfile = async (req, res) => {
  try {
    const userId = req.user.id;
    const updates = req.body;

    const updatedUser = await User.updateProfile(userId, updates);

    res.status(200).json({
      success: true,
      message: 'Profile updated successfully!',
      data: {
        user: updatedUser,
      },
    });
  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred during profile update. Please try again.',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// ========================================
// SETUP MFA
// ========================================
const setupMFA = async (req, res) => {
  try {
    const userId = req.user.id;
    const user = await User.findById(userId);

    const secret = speakeasy.generateSecret({
      name: `Pet Adoption (${user.email})`,
      length: 32,
    });

    await query(
      'UPDATE users SET mfa_secret = $1, mfa_enabled = false WHERE id = $2',
      [secret.base32, userId]
    );

    const qrCodeUrl = await QRCode.toDataURL(secret.otpauth_url);

    res.status(200).json({
      success: true,
      message: 'MFA setup initiated. Please scan the QR code with Google Authenticator.',
      data: {
        secret: secret.base32,
        qrCode: qrCodeUrl,
      },
    });
  } catch (error) {
    console.error('MFA setup error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred during MFA setup. Please try again.',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// ========================================
// VERIFY MFA
// ========================================
const verifyMFA = async (req, res) => {
  try {
    const userId = req.user.id;
    const { token } = req.body;

    const secret = await User.getMFASecret(userId);
    if (!secret) {
      return res.status(400).json({
        success: false,
        message: 'MFA is not set up. Please set up MFA first.',
      });
    }

    const verified = speakeasy.totp.verify({
      secret: secret,
      encoding: 'base32',
      token: token,
      window: 2,
    });

    if (!verified) {
      return res.status(400).json({
        success: false,
        message: 'Invalid MFA token. Please try again.',
      });
    }

    await User.enableMFA(userId, secret);

    res.status(200).json({
      success: true,
      message: 'MFA enabled successfully!',
    });
  } catch (error) {
    console.error('MFA verification error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred during MFA verification. Please try again.',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// ========================================
// MFA LOGIN
// ========================================
const mfaLogin = async (req, res) => {
  try {
    const { email, password, token } = req.body;

    const user = await User.findByEmail(email);
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials.',
      });
    }

    const isPasswordValid = await User.verifyPassword(password, user.password);
    if (!isPasswordValid) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials.',
      });
    }

    const secret = await User.getMFASecret(user.id);
    const verified = speakeasy.totp.verify({
      secret: secret,
      encoding: 'base32',
      token: token,
      window: 2,
    });

    if (!verified) {
      return res.status(400).json({
        success: false,
        message: 'Invalid MFA token.',
      });
    }

    await User.updateLastLogin(user.id);
    const tokens = generateTokens(user);

    res.status(200).json({
      success: true,
      message: 'Login successful!',
      data: {
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          isVerified: user.is_verified,
          isAdmin: user.is_admin,
        },
        ...tokens,
      },
    });
  } catch (error) {
    console.error('MFA login error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred during login. Please try again.',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// ========================================
// DISABLE MFA
// ========================================
const disableMFA = async (req, res) => {
  try {
    const userId = req.user.id;
    const { password } = req.body;

    const user = await User.findByEmail(req.user.email);
    const isPasswordValid = await User.verifyPassword(password, user.password);
    
    if (!isPasswordValid) {
      return res.status(401).json({
        success: false,
        message: 'Invalid password.',
      });
    }

    await User.disableMFA(userId);

    res.status(200).json({
      success: true,
      message: 'MFA disabled successfully.',
    });
  } catch (error) {
    console.error('MFA disable error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred. Please try again.',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// ========================================
// VERIFY EMAIL PAGE (GET - for email links)
// ========================================
const verifyEmailPage = async (req, res) => {
  const { token } = req.query;

  const htmlTemplate = (title, message, isSuccess) => `
    <!DOCTYPE html>
    <html lang="ro">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>${title} - Pet Adoption</title>
      <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
          min-height: 100vh;
          display: flex;
          align-items: center;
          justify-content: center;
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          padding: 20px;
        }
        .container {
          background: white;
          border-radius: 20px;
          padding: 40px;
          max-width: 500px;
          text-align: center;
          box-shadow: 0 20px 60px rgba(0,0,0,0.3);
        }
        .icon {
          font-size: 80px;
          margin-bottom: 20px;
        }
        h1 {
          color: ${isSuccess ? '#4ECDC4' : '#FF6B6B'};
          margin-bottom: 15px;
          font-size: 28px;
        }
        p {
          color: #666;
          font-size: 16px;
          line-height: 1.6;
          margin-bottom: 30px;
        }
        .button {
          display: inline-block;
          padding: 15px 40px;
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          color: white;
          text-decoration: none;
          border-radius: 30px;
          font-weight: 600;
          transition: transform 0.2s, box-shadow 0.2s;
        }
        .button:hover {
          transform: translateY(-2px);
          box-shadow: 0 10px 30px rgba(102, 126, 234, 0.4);
        }
        .paw { color: #667eea; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="icon">${isSuccess ? '✅' : '❌'}</div>
        <h1>${title}</h1>
        <p>${message}</p>
        <p class="paw">🐾 Pet Adoption</p>
      </div>
    </body>
    </html>
  `;

  if (!token) {
    return res.status(400).send(htmlTemplate(
      'Token lipsă',
      'Link-ul de verificare este invalid. Te rugăm să folosești link-ul complet din email.',
      false
    ));
  }

  try {
    const user = await User.verifyEmail(token);

    if (!user) {
      return res.status(400).send(htmlTemplate(
        'Token invalid sau expirat',
        'Link-ul de verificare a expirat sau a fost deja folosit. Te rugăm să soliciți un nou email de verificare din aplicație.',
        false
      ));
    }

    await sendWelcomeEmail(user.email, user.name);

    return res.status(200).send(htmlTemplate(
      'Email verificat cu succes!',
      `Felicitări, ${user.name}! Contul tău a fost activat. Acum poți închide această pagină și te poți autentifica în aplicație.`,
      true
    ));
  } catch (error) {
    console.error('Email verification page error:', error);
    return res.status(500).send(htmlTemplate(
      'Eroare',
      'A apărut o eroare la verificarea email-ului. Te rugăm să încerci din nou mai târziu.',
      false
    ));
  }
};

// ========================================
// EXPORTS
// ========================================
module.exports = {
  register,
  registerAdmin,
  login,
  verifyEmail,
  verifyEmailPage,
  resendVerification,
  forgotPassword,
  resetPassword,
  changePassword,
  refreshToken,
  getCurrentUser,
  updateProfile,
  setupMFA,
  verifyMFA,
  mfaLogin,
  disableMFA,
};