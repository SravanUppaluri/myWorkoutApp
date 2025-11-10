/**
 * Main Firebase Functions Entry Point
 * Routes to different function modules
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");
const express = require("express");
const cors = require("cors");

// Initialize Firebase Admin SDK if not already initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

// Import function modules
const llmSearchFunctions = require("./src/llm-search");
const aiWorkoutRoutes = require("./src/routes/ai-workout");
// const authFunctions = require('./src/auth');
// const analyticsFunctions = require('./src/analytics');
// const notificationFunctions = require('./src/notifications');

// Create Express app for enhanced AI workout API
const aiWorkoutApp = express();

// Enhanced CORS configuration for development and production
const corsOptions = {
  origin: [
    "http://localhost:54799", // Flutter web dev server
    "http://localhost:3000", // React dev server
    "http://localhost:8080", // Alternative dev server
    "https://exerciselist-da299.web.app", // Firebase hosting
    "https://exerciselist-da299.firebaseapp.com", // Firebase hosting alternative
    /^http:\/\/localhost:\d+$/, // Any localhost port
  ],
  credentials: true,
  methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
  allowedHeaders: [
    "Content-Type",
    "Authorization",
    "X-MCP-Context",
    "X-User-ID",
    "Accept",
    "Cache-Control",
    "Pragma",
    "Expires",
    "User-Agent",
    "Access-Control-Request-Method",
    "Access-Control-Request-Headers",
  ],
};

// Enable trust proxy for Firebase Functions
aiWorkoutApp.set("trust proxy", true);

aiWorkoutApp.use(cors(corsOptions));
aiWorkoutApp.use(express.json());

// Add preflight handling for all routes
aiWorkoutApp.options("*", cors(corsOptions));

aiWorkoutApp.use("/api/ai-workout", aiWorkoutRoutes);

// Export LLM Search Functions
exports.searchExerciseWithAI = llmSearchFunctions.searchExerciseWithAI;
exports.generateWorkoutSuggestions =
  llmSearchFunctions.generateWorkoutSuggestions;
exports.getExerciseVariations = llmSearchFunctions.getExerciseVariations;

// Export Enhanced AI Workout API with Firebase MCP
exports.enhancedAIWorkout = functions.https.onRequest(aiWorkoutApp);

// Export Workout AI Functions
exports.generateWorkoutWithAI = llmSearchFunctions.generateWorkoutWithAI;
exports.replaceExerciseWithAI = llmSearchFunctions.replaceExerciseWithAI;
exports.getSimilarExercises = llmSearchFunctions.getSimilarExercises;
exports.generateWorkoutVariations =
  llmSearchFunctions.generateWorkoutVariations;
exports.getWorkoutSuggestions = llmSearchFunctions.getWorkoutSuggestions;

// Export Auth Functions (future)
// exports.createUserProfile = authFunctions.createUserProfile;
// exports.updateUserPreferences = authFunctions.updateUserPreferences;

// Export Analytics Functions (future)
// exports.trackWorkoutCompletion = analyticsFunctions.trackWorkoutCompletion;
// exports.generateProgressReport = analyticsFunctions.generateProgressReport;

// Export Notification Functions (future)
// exports.sendWorkoutReminder = notificationFunctions.sendWorkoutReminder;
// exports.sendAchievementAlert = notificationFunctions.sendAchievementAlert;

// Health check function
exports.healthCheck = functions.https.onRequest((req, res) => {
  res.status(200).json({
    status: "healthy",
    timestamp: new Date().toISOString(),
    version: "1.0.0",
    services: {
      "llm-search": "active",
      auth: "planned",
      analytics: "planned",
      notifications: "planned",
    },
  });
});
