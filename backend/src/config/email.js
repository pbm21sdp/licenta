// src/config/email.js
const nodemailer = require('nodemailer');
require('dotenv').config();

// Create reusable transporter object using SMTP transport
const transporter = nodemailer.createTransport({
  host: process.env.EMAIL_HOST,
  port: parseInt(process.env.EMAIL_PORT),
  secure: process.env.EMAIL_SECURE === 'true', // true for 465, false for other ports
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASSWORD,
  },
});

// Verify transporter configuration
transporter.verify(function (error, success) {
  if (error) {
    console.error('❌ Email configuration error:', error);
  } else {
    console.log('✅ Email server is ready to send messages');
  }
});

/**
 * Send verification email to user
 * @param {string} email - User's email address
 * @param {string} name - User's name
 * @param {string} token - Verification token
 */
const sendVerificationEmail = async (email, name, token) => {
  const verificationUrl = `${process.env.FRONTEND_URL}/verify-email?token=${token}`;
  
  const mailOptions = {
    from: process.env.EMAIL_FROM,
    to: email,
    subject: '🐾 Verifică-ți adresa de email - Pet Adoption',
    html: `
      <!DOCTYPE html>
      <html>
        <head>
          <meta charset="utf-8">
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
            .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
            .button { display: inline-block; padding: 15px 30px; background: #667eea; color: white; text-decoration: none; border-radius: 5px; margin: 20px 0; }
            .footer { text-align: center; margin-top: 20px; color: #888; font-size: 12px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>🐾 Bun venit, ${name}!</h1>
            </div>
            <div class="content">
              <p>Mulțumim că te-ai alăturat comunității noastre de iubitori de animale!</p>
              <p>Pentru a-ți activa contul, te rugăm să îți verifici adresa de email făcând click pe butonul de mai jos:</p>
              <div style="text-align: center;">
                <a href="${verificationUrl}" class="button">Verifică Email-ul</a>
              </div>
              <p>Sau copiază și lipește acest link în browser:</p>
              <p style="word-break: break-all; color: #667eea;">${verificationUrl}</p>
              <p><strong>Link-ul este valabil 24 de ore.</strong></p>
              <p>Dacă nu ai creat acest cont, te rugăm să ignori acest email.</p>
            </div>
            <div class="footer">
              <p>© 2024 Pet Adoption. Toate drepturile rezervate.</p>
            </div>
          </div>
        </body>
      </html>
    `,
  };

  try {
    await transporter.sendMail(mailOptions);
    console.log('✅ Verification email sent to:', email);
  } catch (error) {
    console.error('❌ Error sending verification email:', error);
    throw error;
  }
};

/**
 * Send password reset email to user
 * @param {string} email - User's email address
 * @param {string} name - User's name
 * @param {string} token - Reset token
 */
const sendPasswordResetEmail = async (email, name, token) => {
  const resetUrl = `${process.env.FRONTEND_URL}/reset-password?token=${token}`;
  
  const mailOptions = {
    from: process.env.EMAIL_FROM,
    to: email,
    subject: '🔐 Resetare parolă - Pet Adoption',
    html: `
      <!DOCTYPE html>
      <html>
        <head>
          <meta charset="utf-8">
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
            .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
            .button { display: inline-block; padding: 15px 30px; background: #f5576c; color: white; text-decoration: none; border-radius: 5px; margin: 20px 0; }
            .warning { background: #fff3cd; border-left: 4px solid #ffc107; padding: 10px; margin: 20px 0; }
            .footer { text-align: center; margin-top: 20px; color: #888; font-size: 12px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>🔐 Resetare Parolă</h1>
            </div>
            <div class="content">
              <p>Salut, ${name}!</p>
              <p>Am primit o solicitare de resetare a parolei pentru contul tău.</p>
              <p>Dacă tu ai făcut această solicitare, dă click pe butonul de mai jos pentru a-ți reseta parola:</p>
              <div style="text-align: center;">
                <a href="${resetUrl}" class="button">Resetează Parola</a>
              </div>
              <p>Sau copiază și lipește acest link în browser:</p>
              <p style="word-break: break-all; color: #f5576c;">${resetUrl}</p>
              <div class="warning">
                <strong>⚠️ Important:</strong> Link-ul este valabil doar 1 oră. Dacă expiră, va trebui să soliciți un nou link de resetare.
              </div>
              <p>Dacă nu ai solicitat resetarea parolei, te rugăm să ignori acest email. Parola ta rămâne în siguranță.</p>
            </div>
            <div class="footer">
              <p>© 2024 Pet Adoption. Toate drepturile rezervate.</p>
            </div>
          </div>
        </body>
      </html>
    `,
  };

  try {
    await transporter.sendMail(mailOptions);
    console.log('✅ Password reset email sent to:', email);
  } catch (error) {
    console.error('❌ Error sending password reset email:', error);
    throw error;
  }
};

/**
 * Send welcome email after successful verification
 * @param {string} email - User's email address
 * @param {string} name - User's name
 */
const sendWelcomeEmail = async (email, name) => {
  const mailOptions = {
    from: process.env.EMAIL_FROM,
    to: email,
    subject: '🎉 Bun venit în comunitatea Pet Adoption!',
    html: `
      <!DOCTYPE html>
      <html>
        <head>
          <meta charset="utf-8">
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: linear-gradient(135deg, #84fab0 0%, #8fd3f4 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
            .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
            .footer { text-align: center; margin-top: 20px; color: #888; font-size: 12px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>🎉 Contul tău este activ!</h1>
            </div>
            <div class="content">
              <p>Salut, ${name}!</p>
              <p>Bun venit oficial în comunitatea Pet Adoption! 🐶🐱</p>
              <p>Acum poți:</p>
              <ul>
                <li>Răsfoi animalele disponibile pentru adopție</li>
                <li>Aplica pentru a adopta animalul potrivit</li>
                <li>Salva animalele favorite</li>
                <li>Programa întâlniri cu animalele</li>
                <li>Face donații pentru adăpost</li>
              </ul>
              <p>Fiecare animal merită o familie iubitoare. Împreună facem diferența! ❤️</p>
            </div>
            <div class="footer">
              <p>© 2024 Pet Adoption. Toate drepturile rezervate.</p>
            </div>
          </div>
        </body>
      </html>
    `,
  };

  try {
    await transporter.sendMail(mailOptions);
    console.log('✅ Welcome email sent to:', email);
  } catch (error) {
    console.error('❌ Error sending welcome email:', error);
    throw error;
  }
};

module.exports = {
  transporter,
  sendVerificationEmail,
  sendPasswordResetEmail,
  sendWelcomeEmail,
};