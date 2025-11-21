/**
 * AI Prompts for Exercise and Fitness Related Queries
 */

/**
 * Generate a prompt for exercise search
 * @param {string} exerciseName - Name of the exercise to search for
 * @returns {string} Formatted prompt for OpenAI
 */
function buildExerciseSearchPrompt(exerciseName) {
  return `Exercise: "${exerciseName}"

Invalid? {"error":"not_found","message":"Not exercise"}

Valid? JSON:
{"name":"Name","category":"Strength|Cardio|Flexibility","equipment":["item"],"primaryMuscles":["muscle"],"difficulty":"Beginner|Intermediate|Advanced","muscleGroup":"Chest|Back|Shoulders|Arms|Legs|Core|Full Body"}

Short names only. Use "Bodyweight" if no equipment.`;
}

/**
 * Generate a prompt for exercise variations
 * @param {string} baseExercise - Base exercise to find variations for
 * @param {number} count - Number of variations to generate (default: 3)
 * @returns {string} Formatted prompt for OpenAI
 */
function buildExerciseVariationsPrompt(baseExercise, count = 3) {
  return `${count} variations of "${baseExercise}":

[{"name":"","category":"Strength|Cardio|Flexibility","equipment":[""],"primaryMuscles":[""],"difficulty":"Beginner|Intermediate|Advanced","muscleGroup":"Chest|Back|Shoulders|Arms|Legs|Core|Full Body"}]

Similar muscles, different technique. Short names.`;
}

/**
 * Generate a prompt for workout suggestions (future feature)
 * @param {object} userProfile - User's fitness profile
 * @param {string} goal - Workout goal
 * @returns {string} Formatted prompt for OpenAI
 */
function buildWorkoutSuggestionPrompt(userProfile, goal) {
  return `
You are a professional fitness trainer. Create a workout plan based on:

User Profile:
- Fitness Level: ${userProfile.fitnessLevel}
- Available Equipment: ${userProfile.equipment?.join(", ") || "Bodyweight only"}
- Target Areas: ${userProfile.targetAreas?.join(", ") || "Full body"}
- Time Available: ${userProfile.timeAvailable || "30 minutes"}

Goal: ${goal}

Return a structured workout plan with exercises, sets, reps, and rest periods.
[This is a placeholder for future implementation]
`;
}

module.exports = {
  buildExerciseSearchPrompt,
  buildExerciseVariationsPrompt,
  buildWorkoutSuggestionPrompt,
};
