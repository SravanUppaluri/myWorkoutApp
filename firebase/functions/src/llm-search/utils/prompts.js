/**
 * AI Prompts for Exercise and Fitness Related Queries
 */

/**
 * Generate a prompt for exercise search
 * @param {string} exerciseName - Name of the exercise to search for
 * @returns {string} Formatted prompt for OpenAI
 */
function buildExerciseSearchPrompt(exerciseName) {
  return `
You are a professional fitness expert. Analyze the input: "${exerciseName}"

FIRST, determine if this is a valid exercise-related query:
- Must be a real exercise name, muscle group, or fitness movement
- Must not be gibberish, random characters, or nonsensical text
- Must be related to fitness, exercise, or physical activity

IF THE INPUT IS NOT A VALID EXERCISE OR FITNESS TERM:
Return exactly this JSON: {"error": "not_found", "message": "No valid exercise found for this search term"}

IF THE INPUT IS VALID, return detailed exercise information in this EXACT format:
{
  "name": "Proper Exercise Name",
  "category": "Strength|Cardio|Flexibility|Sports|Functional",
  "equipment": ["Equipment1", "Equipment2"],
  "primaryMuscles": ["Muscle1", "Muscle2"],
  "secondaryMuscles": ["Muscle1", "Muscle2"],
  "difficulty": "Beginner|Intermediate|Advanced",
  "movementType": "Compound|Isolation",
  "movementPattern": "Push|Pull|Squat|Hinge|Carry|Rotation",
  "targetRegion": ["Upper Body|Lower Body|Core|Full Body"],
  "muscleGroup": "Chest|Back|Shoulders|Arms|Legs|Core|Full Body",
  "gripType": "Standard|Wide|Narrow|Neutral|Overhand|Underhand",
  "rangeOfMotion": "Full|Partial|Static",
  "tempo": "Slow|Moderate|Fast|Explosive"
}

VALIDATION RULES FOR INVALID INPUT:
- Random characters like "asdfgh", "12345", "!@#$%" = INVALID
- Gibberish words like "blahblah", "xyz123" = INVALID  
- Non-fitness terms like "car", "computer", "pizza" = INVALID
- Very short inputs under 2 characters = INVALID
- Offensive or inappropriate content = INVALID

VALID INPUT EXAMPLES:
- "push ups", "squat", "bicep curl", "deadlift"
- "chest exercise", "leg workout", "core movement"
- Misspelled but recognizable: "pushup", "sqwat", "burpe"

CRITICAL REQUIREMENTS FOR VALID EXERCISES:
- Use proper anatomical muscle names (Quadriceps, Hamstrings, Pectorals, etc.)
- Equipment must be realistic and commonly available
- ALL ARRAYS MUST CONTAIN AT LEAST ONE ITEM - NEVER EMPTY
- Equipment array MUST include at least one item (use "Bodyweight" if no equipment needed)
- PrimaryMuscles array MUST include at least one muscle group
- TargetRegion array MUST include at least one region
- Category must be one of the 5 listed options
- Common equipment: Dumbbell, Barbell, Resistance Band, Cable Machine, Bodyweight, Pull-up Bar
`;
}

/**
 * Generate a prompt for exercise variations
 * @param {string} baseExercise - Base exercise to find variations for
 * @param {number} count - Number of variations to generate (default: 3)
 * @returns {string} Formatted prompt for OpenAI
 */
function buildExerciseVariationsPrompt(baseExercise, count = 3) {
  return `
You are a professional fitness expert. Generate ${count} exercise variations for: "${baseExercise}"

Return ONLY valid JSON array in this EXACT format:
[
  {
    "name": "Variation Name",
    "category": "Strength|Cardio|Flexibility|Sports|Functional",
    "equipment": ["Equipment1"],
    "primaryMuscles": ["Muscle1", "Muscle2"],
    "secondaryMuscles": ["Muscle1"],
    "difficulty": "Beginner|Intermediate|Advanced",
    "movementType": "Compound|Isolation",
    "movementPattern": "Push|Pull|Squat|Hinge|Carry|Rotation",
    "targetRegion": ["Upper Body|Lower Body|Core|Full Body"],
    "muscleGroup": "Chest|Back|Shoulders|Arms|Legs|Core|Full Body",
    "gripType": "Standard|Wide|Narrow|Neutral|Overhand|Underhand",
    "rangeOfMotion": "Full|Partial|Static",
    "tempo": "Slow|Moderate|Fast|Explosive"
  }
]

CRITICAL REQUIREMENTS:
- Each variation should target similar muscles but use different technique/equipment
- Provide a progression from easier to harder variations
- Ensure each variation is distinct and practical
- Use proper anatomical terms
- ALL ARRAYS MUST CONTAIN AT LEAST ONE ITEM - NEVER EMPTY
- Equipment array MUST include at least one item (use "Bodyweight" if no equipment needed)
- PrimaryMuscles array MUST include at least one muscle group
- TargetRegion array MUST include at least one region
- All enum values must match exactly (case-sensitive)
- If bodyweight exercise, use ["Bodyweight"] for equipment
- Common equipment: Dumbbell, Barbell, Resistance Band, Cable Machine, Bodyweight, Pull-up Bar
`;
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
