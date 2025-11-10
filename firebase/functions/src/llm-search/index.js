/**
 * LLM Search Functions Module
 * Handles AI-powered search and generation features
 */

const functions = require("firebase-functions");
const exerciseAI = require("./exercise-ai");
const workoutAI = require("./workout-ai");
// const nutritionAI = require('./nutrition-ai');

module.exports = {
  // Exercise AI Functions
  searchExerciseWithAI: exerciseAI.searchExerciseWithAI,
  getExerciseVariations: exerciseAI.getExerciseVariations,

  // Workout AI Functions
  generateWorkoutWithAI: workoutAI.generateWorkoutWithAI,
  replaceExerciseWithAI: workoutAI.replaceExerciseWithAI,
  getSimilarExercises: workoutAI.getSimilarExercises,
  generateWorkoutVariations: workoutAI.generateWorkoutVariations,
  getWorkoutSuggestions: workoutAI.getWorkoutSuggestions,

  // Legacy/Placeholder Functions
  generateWorkoutSuggestions: functions.https.onCall(async (data, context) => {
    // Redirect to new function
    return workoutAI.generateWorkoutWithAI(data, context);
  }),

  // Nutrition AI Functions (future)
  getNutritionAdvice: functions.https.onCall(async (data, context) => {
    // Placeholder for future implementation
    throw new functions.https.HttpsError(
      "unimplemented",
      "Nutrition advice not implemented yet"
    );
  }),
};
