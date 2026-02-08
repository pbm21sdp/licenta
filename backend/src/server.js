// src/server.js

// importuri pentru librarii externe
const express = require('express'); //  framework-ul principal pentru server (face routing, handle requests)
const cors = require('cors'); // permite frontend-ului (Flutter) sa comunice cu backend-ul (cross-origin)
const helmet = require('helmet'); // adauga headers de securitate (protejează de atacuri comune)
const rateLimit = require('express-rate-limit'); // limiteaza cate request-uri poate face cineva (ex: max 100 in 15 min)
const session = require('express-session'); // tine minte utilizatorul intre request-uri (pentru OAuth - Google/Facebook login)
const passport = require('./config/passport'); // librarie pentru autentificare (Google, Facebook, Apple login)
require('dotenv').config(); // citeste fisierul .env si incarca variabilele (PORT, DB_PASSWORD, etc.)

// Import pentru routes
const authRoutes = require('./routes/auth.routes'); // importa toate rutele de autentificare (login, register, etc.)
const petRoutes = require('./routes/pet.routes'); // importa rutele pentru animale
const favoriteRoutes = require('./routes/favorite.routes'); // importa rutele pentru favorite
const adoptionRoutes = require('./routes/adoption.routes'); // importa rutele pentru adoptii
const preferenceRoutes = require('./routes/preference.routes'); // importa rutele pentru preferinte utilizator
const adminRoutes = require('./routes/admin.routes'); // importa rutele pentru administrare (deprecated)

// Peer-to-peer routes (new)
const userPetsRoutes = require('./routes/user-pets.routes'); // rutele pentru gestionarea animalelor proprii
const ownerAdoptionsRoutes = require('./routes/owner-adoptions.routes'); // rutele pentru gestionarea cererilor de adopție primite
const userProfileRoutes = require('./routes/user-profile.routes'); // rutele pentru profile publice

// Import pentru database
const { pool } = require('./config/database'); // importa conexiunea la PostgreSQL database

// Initializarea aplicatiei Express 
const app = express(); // creeaza instanta Express = serverul 

// Helmet - security headers
app.use(helmet()); // adauga headers HTTP de securitate automat 

// CORS - Configure Cross-Origin Resource Sharing
const corsOptions = {
  origin: process.env.CORS_ORIGIN
    ? process.env.CORS_ORIGIN.split(',') // permite doar unor anumite URL-uri sa acceseze API-ul, pentru ca flutter ruleaza pe alt port si trebuie permis explicit
    : true, // În development, permite toate originile (Flutter web rulează pe porturi random)
  credentials: true, // permite cookies si autentificare cross-origin
  optionsSuccessStatus: 200,
};
app.use(cors(corsOptions)); // activeaza CORS cu setarile de mai sus

// Rate limiting - pentru prevenirea atacurilor de tip brute force
const limiter = rateLimit({ // daca cineva face mai mult de 100 requests in 15 minute, il blochează
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000, // 15 minute
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100, // limiteaza fiecare IP la 100 requests per windowMs
  message: 'Too many requests from this IP, please try again later.',
  standardHeaders: true,
  legacyHeaders: false,
});
app.use('/api/', limiter); // aplica limita la toate rutele /api/*

// Rate limit mai strict pentru auth endpoints
const authLimiter = rateLimit({ // pentru login/register, doar 20 incercari in 15 minute - previne atacuri de tip brute force / ghicirea parolei
  windowMs: 15 * 60 * 1000, // 15 minute
  max: 20, // 20 requests per 15 minute
  message: 'Too many authentication attempts, please try again later.',
  standardHeaders: true,
  legacyHeaders: false,
});

app.use(express.json({ limit: '10mb' })); // permite serverului sa citească JSON din request-uri, maxim 10MB de date pentru upload de imagini
app.use(express.urlencoded({ extended: true, limit: '10mb' })); // permite citirea datelor din formulare HTML

app.use(
  session({
    secret: process.env.SESSION_SECRET || 'your-secret-key', // creează o "sesiune" pentru fiecare utilizator, pentru ca OAuth are nevoie de sesiune sa tina minte user-ul intre redirect-uri
    resave: false, // optimizare pentru performanta
    saveUninitialized: false, // optimizare pentru performanta
    cookie: {
      secure: process.env.NODE_ENV === 'production', // HTTPS doar in productie
      httpOnly: true, // JavaScript nu poate citi cookie-ul (securitate)
      maxAge: 24 * 60 * 60 * 1000, // cookie-ul expira dupa 24 de ore
    },
  })
);

app.use(passport.initialize()); // activeaza Passport pentru Google/Facebook/Apple login
app.use(passport.session()); // activeaza Passport pentru Google/Facebook/Apple login

// Ruta simpla pentru a verifica daca serverul functioneaza
app.get('/health', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Pet Adoption API is running!',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
  });
});

// Mesaj de bun venit la root URL
app.get('/', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Welcome to Pet Adoption API 🐾',
    version: process.env.API_VERSION || 'v1',
    documentation: '/api/docs',
  });
});

// Auth routes (with rate limiting)
app.use(`/api/${process.env.API_VERSION || 'v1'}/auth`, authLimiter, authRoutes);

// Pet routes (public + protected)
app.use(`/api/${process.env.API_VERSION || 'v1'}/pets`, petRoutes);

// Favorite routes (protected)
app.use(`/api/${process.env.API_VERSION || 'v1'}/favorites`, favoriteRoutes);

// Adoption routes (protected)
app.use(`/api/${process.env.API_VERSION || 'v1'}/adoptions`, adoptionRoutes);

// User preferences routes (protected)
app.use(`/api/${process.env.API_VERSION || 'v1'}/preferences`, preferenceRoutes);

// Admin routes (protected + admin only) - DEPRECATED
app.use(`/api/${process.env.API_VERSION || 'v1'}/admin`, adminRoutes);

// ==========================================
// PEER-TO-PEER ROUTES (NEW)
// ==========================================

// My pets routes (authenticated users can manage their own pets)
app.use(`/api/${process.env.API_VERSION || 'v1'}/my-pets`, userPetsRoutes);

// Owner adoptions routes (pet owners manage adoption requests)
app.use(`/api/${process.env.API_VERSION || 'v1'}/owner/adoptions`, ownerAdoptionsRoutes);

// User profile routes (public profiles and user search)
app.use(`/api/${process.env.API_VERSION || 'v1'}/users`, userProfileRoutes);


// 404 handler - Route not found
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'Route not found',
    path: req.originalUrl,
  });
});

// Global error handler
app.use((err, req, res, next) => {
  console.error('Global error handler:', err);

  // Default error status and message
  const status = err.status || 500;
  const message = err.message || 'Internal server error';

  res.status(status).json({
    success: false,
    message: message,
    error: process.env.NODE_ENV === 'development' ? err.stack : undefined,
  });
});


const PORT = process.env.PORT || 5000;

// Test database connection before starting server
pool
  .query('SELECT NOW()')
  .then(() => {
    console.log('✅ Database connection successful');
    
    // Start server
    app.listen(PORT, () => {
      console.log(`
PET ADOPTION API SERVER STARTED

Environment: ${process.env.NODE_ENV || 'development'}
Port:        ${PORT}
API Version: ${process.env.API_VERSION || 'v1'}

Health:      http://localhost:${PORT}/health
Auth:        http://localhost:${PORT}/api/v1/auth
Pets:        http://localhost:${PORT}/api/v1/pets
Favorites:   http://localhost:${PORT}/api/v1/favorites
Adoptions:   http://localhost:${PORT}/api/v1/adoptions
Preferences: http://localhost:${PORT}/api/v1/preferences
My Pets:     http://localhost:${PORT}/api/v1/my-pets
Owner:       http://localhost:${PORT}/api/v1/owner/adoptions
Users:       http://localhost:${PORT}/api/v1/users
Admin:       http://localhost:${PORT}/api/v1/admin (deprecated)

      `);
    });
  })
  .catch((err) => {
    console.error('Database connection failed:', err);
    console.error('Please check your database configuration in .env file');
    process.exit(1);
  });

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM signal received: closing HTTP server');
  pool.end(() => {
    console.log('Database pool closed');
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  console.log('SIGINT signal received: closing HTTP server');
  pool.end(() => {
    console.log('Database pool closed');
    process.exit(0);
  });
});

module.exports = app;