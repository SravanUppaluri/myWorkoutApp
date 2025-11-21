/**
 * AI Workout Generation Functions
 * Handles AI-powered workout creation and optimization
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");
const cors = require("cors")({origin: true});
const geminiClient = require("./utils/gemini-client-fixed");

/**
 * Get user's recent workout history for context
 */
async function getRecentWorkoutHistory(userId, days = 4) {
  try {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - days);

    const workoutSessionsSnapshot = await admin
      .firestore()
      .collection("workoutSessions")
      .where("userId", "==", userId)
      .where("completedAt", ">=", cutoffDate)
      .orderBy("completedAt", "desc")
      .limit(10)
      .get();

    const recentWorkouts = [];
    workoutSessionsSnapshot.docs.forEach((doc) => {
      const data = doc.data();
      if (data.exercises && Array.isArray(data.exercises)) {
        const exerciseNames = data.exercises
          .map((ex) => ex.exerciseName || ex.name)
          .filter(Boolean);
        recentWorkouts.push({
          date: data.completedAt.toDate
            ? data.completedAt.toDate().toISOString().split("T")[0]
            : data.completedAt,
          exercises: exerciseNames,
          duration: data.duration || 0,
          workoutType: data.workoutType || "Unknown",
        });
      }
    });

    return recentWorkouts;
  } catch (error) {
    console.error("Error fetching workout history:", error);
    return [];
  }
}

/**
 * Generate a complete workout using AI based on user preferences
 */
exports.generateWorkoutWithAI = functions.https.onCall(
  async (data, context) => {
    try {
      console.log(
        "📥 Raw request data received:",
        JSON.stringify(data, null, 2)
      );

      // Handle both old and new parameter formats
      const {
        goal,
        fitnessLevel,
        workoutType,
        duration,
        muscleGroups,
        equipment,
        additionalNotes,
        userId,
        // New parameters from Flutter app
        focusArea,
        primaryMuscles,
        instructions,
      } = data;

      // Map new parameters to old format for backward compatibility
      const mappedMuscleGroups =
        muscleGroups || primaryMuscles || (focusArea ? [focusArea] : []);

      const mappedAdditionalNotes = additionalNotes || instructions || "";
      const mappedWorkoutType = workoutType || "General Fitness";

      console.log("🔄 Mapped parameters:", {
        originalGoal: goal,
        mappedMuscleGroups,
        mappedAdditionalNotes,
        mappedWorkoutType,
        focusArea,
        primaryMuscles,
        instructions,
      });

      if (!goal || typeof goal !== "string") {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "Goal is required and must be a string"
        );
      }

      // Check if Gemini is configured
      if (!geminiClient.isConfigured()) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "AI service is not configured. Please contact support."
        );
      }

      // Get user's recent workout history (last 4 days)
      let recentWorkoutHistory = null;
      if (userId) {
        try {
          recentWorkoutHistory = await getRecentWorkoutHistory(userId, 4);
        } catch (error) {
          console.log("Could not fetch workout history:", error);
          // Continue without history if fetch fails
        }
      }

      // Optional: Rate limiting
      if (context.auth) {
        const userDoc = await admin
          .firestore()
          .collection("users")
          .doc(context.auth.uid)
          .get();

        if (userDoc.exists) {
          const userData = userDoc.data();
          const today = new Date().toDateString();
          const dailyUsage = userData.aiWorkoutUsage?.[today] || 0;

          // Get daily limit from environment or default to 5 for production, 100 for development
          const dailyLimit =
            parseInt(process.env.DAILY_AI_SEARCH_LIMIT) ||
            (process.env.NODE_ENV === "development" ? 100 : 5);

          console.log(
            `Daily AI usage check: ${dailyUsage}/${dailyLimit} (Environment: ${process.env.NODE_ENV})`
          );

          // Check if user has exceeded daily limit
          if (dailyUsage >= dailyLimit) {
            throw new functions.https.HttpsError(
              "resource-exhausted",
              `Daily AI workout generation limit (${dailyLimit}) reached. Please try again tomorrow.`
            );
          }
        }
      }

      console.log(
        `AI Workout Generation: Goal="${goal}", Level="${fitnessLevel}", Type="${workoutType}"`
      );
      if (recentWorkoutHistory && recentWorkoutHistory.length > 0) {
        console.log(
          `Found ${recentWorkoutHistory.length} recent workout sessions`
        );
      }

      // Generate prompt for workout creation
      const prompt = buildWorkoutGenerationPrompt({
        goal,
        fitnessLevel,
        workoutType: mappedWorkoutType,
        duration,
        muscleGroups: mappedMuscleGroups,
        equipment,
        additionalNotes: mappedAdditionalNotes,
        recentWorkoutHistory,
        focusArea, // Pass original focusArea for better targeting
      });

      // Call Gemini API
      console.log("=== CALLING GEMINI API ===");
      console.log("Prompt length:", prompt.length);
      console.log("API Configuration:", {
        maxTokens: 3500,
        temperature: 0.7,
      });

      let aiResponse;
      try {
        aiResponse = await geminiClient.generateContent(prompt, {
          maxTokens: 1500,
          temperature: 0.7,
        });
      } catch (error) {
        console.error("⚠️ Primary prompt failed:", error.message);

        // If "No text content" error, try a simpler prompt
        if (
          error.message.includes("No text content") ||
          error.message.includes("No content generated") ||
          error.message.includes("Empty text")
        ) {
          console.log("🔄 Trying simplified prompt...");
          const simplePrompt = `Create a ${duration}-minute ${workoutType} workout for ${fitnessLevel} level. 
Return only JSON format:
{
  "name": "Workout Name",
  "description": "Description",
  "difficulty": "${fitnessLevel}",
  "estimatedDuration": ${duration},
  "exercises": [
    {
      "name": "Exercise Name",
      "type": "Strength",
      "muscleGroups": ["Chest"],
      "sets": [{"reps": 12, "weight": 0}],
      "restTime": 60
    }
  ]
}`;

          aiResponse = await geminiClient.generateContent(simplePrompt, {
            maxTokens: 3800,
            temperature: 0.5,
          });
        } else {
          throw error;
        }
      }

      console.log("=== RAW AI RESPONSE ===");
      console.log("Response type:", typeof aiResponse);
      console.log("Response length:", aiResponse?.length || "N/A");
      console.log("Full AI Response:", aiResponse);
      console.log(
        "Response preview (first 500 chars):",
        aiResponse?.substring(0, 500)
      );

      // Parse the response
      let workoutData;
      try {
        console.log("=== JSON PARSING PROCESS ===");

        // Multiple cleaning attempts
        let cleanResponse = aiResponse
          .replace(/```json\s*|\s*```/g, "") // Remove code blocks
          .replace(/```\s*|\s*```/g, "") // Remove any remaining backticks
          .trim();

        console.log(
          "After removing code blocks:",
          cleanResponse.substring(0, 200) + "..."
        );

        // Remove any leading/trailing text that might not be JSON
        const jsonStart = cleanResponse.indexOf("{");
        const jsonEnd = cleanResponse.lastIndexOf("}") + 1;

        console.log("JSON boundaries found:", {jsonStart, jsonEnd});

        if (jsonStart !== -1 && jsonEnd > jsonStart) {
          cleanResponse = cleanResponse.substring(jsonStart, jsonEnd);
          console.log(
            "Extracted JSON portion:",
            cleanResponse.substring(0, 300) + "..."
          );
        }

        console.log("=== ATTEMPTING JSON PARSE ===");
        console.log("Final cleaned response length:", cleanResponse.length);

        // Attempt to parse JSON
        workoutData = JSON.parse(cleanResponse);
        console.log("=== JSON PARSE SUCCESS ===");
        console.log(
          "Parsed workout data keys:",
          Object.keys(workoutData || {})
        );
        console.log(
          "Number of exercises:",
          workoutData?.exercises?.length || 0
        );
      } catch (parseError) {
        console.error("=== JSON PARSE FAILED ===");
        console.error("Parse Error:", parseError.message);
        console.error("Error stack:", parseError.stack);
        console.error("Attempted to parse length:", cleanResponse?.length || 0);
        console.error(
          "First 500 chars of cleaned response:",
          cleanResponse?.substring(0, 500) + "..."
        );

        // Try to extract JSON from the response if it's embedded in text
        console.log("=== ATTEMPTING FALLBACK PARSING ===");
        try {
          const jsonMatch = aiResponse.match(/\{[\s\S]*\}/);
          if (jsonMatch) {
            console.log("Found JSON match, length:", jsonMatch[0].length);
            console.log(
              "JSON match preview:",
              jsonMatch[0].substring(0, 300) + "..."
            );
            workoutData = JSON.parse(jsonMatch[0]);
            console.log("Fallback parse SUCCESS");
          } else {
            console.log("No JSON object pattern found in response");
            throw new Error("No JSON object found in response");
          }
        } catch (secondParseError) {
          console.error("=== FALLBACK PARSE ALSO FAILED ===");
          console.error("Second parse error:", secondParseError.message);
          throw new functions.https.HttpsError(
            "internal",
            `AI returned invalid format. Parse error: ${
              parseError.message
            }. Response preview: ${aiResponse.substring(0, 200)}...`
          );
        }
      }

      console.log("=== DATA CLEANING PHASE ===");
      console.log("Pre-cleaning workout data structure:", {
        hasName: !!workoutData?.name,
        hasDescription: !!workoutData?.description,
        hasExercises: !!workoutData?.exercises,
        exerciseCount: workoutData?.exercises?.length || 0,
        hasTargetMuscleGroups: !!workoutData?.targetMuscleGroups,
      });

      // Clean and fix common AI response issues
      workoutData = cleanWorkoutData(workoutData);

      console.log("=== POST-CLEANING DATA ===");
      console.log("Post-cleaning structure:", {
        name: workoutData?.name,
        exerciseCount: workoutData?.exercises?.length || 0,
        targetMuscles: workoutData?.targetMuscleGroups,
        estimatedDuration: workoutData?.estimatedDuration,
      });

      if (workoutData?.exercises?.length > 0) {
        console.log("First exercise structure:", {
          name: workoutData.exercises[0]?.name,
          type: workoutData.exercises[0]?.type,
          setsCount: workoutData.exercises[0]?.sets?.length || 0,
          firstSet: workoutData.exercises[0]?.sets?.[0],
        });
      }

      console.log("=== VALIDATION PHASE ===");
      // Validate the workout data
      const validationResult = validateWorkoutData(workoutData);

      console.log("Validation result:", {
        isValid: validationResult.isValid,
        errorCount: validationResult.errors?.length || 0,
      });

      if (!validationResult.isValid) {
        console.error("=== VALIDATION FAILED ===");
        console.error(
          "Full workout data:",
          JSON.stringify(workoutData, null, 2)
        );
        console.error("All validation errors:", validationResult.errors);
        throw new functions.https.HttpsError(
          "internal",
          `AI generated invalid workout data: ${validationResult.errors.join(
            ", "
          )}`
        );
      }

      console.log("=== VALIDATION SUCCESS ===");

      // Enhance with metadata
      const enhancedWorkoutData = {
        ...workoutData,
        id: `ai_workout_${Date.now()}_${Math.random()
          .toString(36)
          .substr(2, 9)}`,
        createdAt: new Date().toISOString(),
        source: "ai_generated",
        userPreferences: {
          goal,
          fitnessLevel,
          workoutType,
          duration,
          muscleGroups,
          equipment,
        },
      };

      // Update user's daily usage counter
      if (context.auth?.uid) {
        const today = new Date().toDateString();
        await admin
          .firestore()
          .collection("users")
          .doc(context.auth.uid)
          .set(
            {
              aiWorkoutUsage: {
                [today]: admin.firestore.FieldValue.increment(1),
              },
            },
            {merge: true}
          );
      }

      console.log("=== WORKOUT GENERATION SUCCESS ===");
      console.log(`Generated workout: "${enhancedWorkoutData.name}"`);
      console.log(`Duration: ${enhancedWorkoutData.estimatedDuration} minutes`);
      console.log(`Exercises: ${enhancedWorkoutData.exercises?.length || 0}`);
      console.log(
        `Target muscles: ${enhancedWorkoutData.targetMuscleGroups?.join(", ")}`
      );
      console.log("Final workout data keys:", Object.keys(enhancedWorkoutData));

      return enhancedWorkoutData;
    } catch (error) {
      console.error("Error in generateWorkoutWithAI:", error);
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }
      throw new functions.https.HttpsError(
        "internal",
        "Failed to generate workout"
      );
    }
  }
);

/**
 * Build prompt for AI workout generation
 */
function buildWorkoutGenerationPrompt(preferences) {
  const {
    goal,
    fitnessLevel,
    workoutType,
    duration,
    muscleGroups,
    equipment,
    additionalNotes,
    recentWorkoutHistory,
    focusArea,
  } = preferences;

  let workoutHistoryText = "";
  if (recentWorkoutHistory && recentWorkoutHistory.length > 0) {
    workoutHistoryText = `
RECENT WORKOUT HISTORY (Last 4 Days):
${recentWorkoutHistory
  .map(
    (session, index) =>
      `${index + 1}. ${session.workoutName || "Workout"} (${
        session.date
      }): ${session.exercises.join(", ")}`
  )
  .join("\n")}

IMPORTANT: Avoid repeating the same exercises from recent workouts unless specifically needed for the user's goal. Create variety while maintaining progression.
`;
  }

  // Enhanced focus area handling
  const targetMuscles =
    muscleGroups?.join(", ") || focusArea || "Not specified";
  const specificFocus =
    focusArea ||
    (muscleGroups && muscleGroups.length === 1 ? muscleGroups[0] : null);

  let focusInstructions = "";
  if (specificFocus && specificFocus.toLowerCase() !== "full body") {
    focusInstructions = `
🎯 CRITICAL FOCUS REQUIREMENT: 
This workout MUST primarily target ${specificFocus.toUpperCase()} muscles. 
- At least 70% of exercises should directly target ${specificFocus}
- Include both compound and isolation movements for ${specificFocus}
- Avoid generic full-body exercises unless they specifically emphasize ${specificFocus}
- For Arms: Focus on biceps, triceps, shoulders, forearms
- For Chest: Focus on pectorals, front deltoids
- For Legs: Focus on quadriceps, hamstrings, glutes, calves
- For Core: Focus on abs, obliques, lower back stabilization
`;
  }

  return `
You are a professional fitness trainer and exercise physiologist. Create a personalized workout plan based on the following requirements:

USER PROFILE:
- Goal: ${goal}
- Fitness Level: ${fitnessLevel}
- Preferred Workout Type: ${workoutType}
- Duration: ${duration} minutes
- Target Muscle Groups: ${targetMuscles}
- Available Equipment: ${equipment?.join(", ") || "Bodyweight only"}
- Additional Notes: ${additionalNotes || "None"}
${focusInstructions}
${workoutHistoryText}

CRITICAL INSTRUCTIONS:
1. Return ONLY a valid JSON object - no explanatory text before or after
2. Do not use markdown code blocks or backticks  
3. Ensure all string values use double quotes, not single quotes
4. All numbers must be valid numbers (not strings)
5. Weight values must be 0 or positive numbers (use 0 for bodyweight exercises)

EXACT JSON FORMAT REQUIRED:
{
  "name": "Descriptive Workout Name",
  "description": "Brief description of the workout and its benefits",
  "difficulty": "Beginner",
  "estimatedDuration": ${duration},
  "targetMuscleGroups": ["Chest", "Back", "Legs"],
  "exercises": [
    {
      "id": "exercise_1",
      "name": "Push-ups",
      "type": "Strength",
      "equipment": ["Bodyweight"],
      "muscleGroups": ["Chest", "Triceps", "Shoulders"],
      "difficulty": "Beginner",
      "instructions": "Start in plank position with hands shoulder-width apart. Lower chest to floor, then push back up maintaining straight body line.",
      "sets": [
        {"reps": 12, "weight": 0},
        {"reps": 12, "weight": 0},
        {"reps": 12, "weight": 0}
      ],
      "restTime": 60,
      "notes": "Keep core engaged throughout movement"
    }
  ]
}

IMPORTANT FORMATTING RULES:
- ALL weights must be numbers (0 for bodyweight exercises)
- ALL reps must be positive integers
- Sets array must contain at least 1 set object
- Each set MUST have both "reps" and "weight" as numbers
- For bodyweight exercises, use weight: 0
- For weighted exercises, suggest appropriate starting weights
- NO null values, NO strings for numeric fields

WORKOUT CREATION GUIDELINES:
1. Design ${Math.ceil(duration / 8)} to ${Math.ceil(
    duration / 5
  )} exercises for ${duration} minutes
2. Match difficulty to user's fitness level: ${fitnessLevel}
3. Focus on goal: ${goal}
4. Use only available equipment: ${equipment?.join(", ") || "Bodyweight"}
5. DO NOT include warm-up or cool-down exercises - focus ONLY on main workout exercises
6. Ensure balanced muscle group targeting
7. Progressive overload appropriate for ${fitnessLevel} level
8. ALL REQUIRED FIELDS MUST BE PROVIDED:
   - Each exercise MUST have: name, type, muscleGroups, instructions, sets
   - Top level MUST have: name, description, targetMuscleGroups, estimatedDuration, exercises
   - Sets must be an array with at least one set object containing reps
9. Sets/reps should match fitness level and goal
10. Rest times: Strength (60-90s), Cardio (30-45s), Endurance (45-60s)
11. Instructions must be detailed step-by-step form guidance

FITNESS LEVEL ADJUSTMENTS:
- Beginner: Simple movements, 2-3 sets, 8-12 reps, longer rest
- Intermediate: Moderate complexity, 3-4 sets, 8-15 reps, standard rest
- Advanced: Complex movements, 3-5 sets, varied rep ranges, shorter rest

GOAL-SPECIFIC FOCUS:
- Muscle Building: Compound + isolation, 6-12 reps, heavier emphasis
- Weight Loss: Circuit style, higher reps, shorter rest, cardio elements
- Strength: Compound movements, 3-6 reps, longer rest
- Endurance: Higher reps, 12-20 range, moderate rest
- General Fitness: Balanced approach, functional movements

Ensure the workout is safe, effective, and matches the user's specified preferences exactly.
`;
}

/**
 * Clean and fix common AI response issues
 */
function cleanWorkoutData(data) {
  if (!data || typeof data !== "object") return data;

  // Ensure required top-level fields exist
  if (!data.targetMuscleGroups) data.targetMuscleGroups = [];
  if (!data.estimatedDuration) data.estimatedDuration = 30;
  if (!data.exercises) data.exercises = [];

  // Clean each exercise
  if (Array.isArray(data.exercises)) {
    data.exercises = data.exercises.map((exercise) => {
      if (!exercise || typeof exercise !== "object") return exercise;

      // Ensure required fields
      if (!exercise.name) exercise.name = "Unknown Exercise";
      if (!exercise.type) exercise.type = "Strength";
      if (!exercise.muscleGroups) exercise.muscleGroups = ["Full Body"];
      if (!exercise.instructions)
        exercise.instructions = "Perform the exercise with proper form.";
      if (!exercise.sets) exercise.sets = [];

      // Clean sets array
      if (Array.isArray(exercise.sets)) {
        exercise.sets = exercise.sets.map((set) => {
          if (!set || typeof set !== "object") return {reps: 12, weight: 0};

          // Fix reps
          if (typeof set.reps !== "number" || set.reps <= 0) {
            set.reps = 12;
          }

          // Fix weight - ensure it's a number
          if (
            set.weight === null ||
            set.weight === undefined ||
            typeof set.weight !== "number"
          ) {
            set.weight = 0;
          }
          if (set.weight < 0) {
            set.weight = 0;
          }

          return set;
        });
      }

      // Ensure at least one set
      if (!Array.isArray(exercise.sets) || exercise.sets.length === 0) {
        exercise.sets = [{reps: 12, weight: 0}];
      }

      return exercise;
    });
  }

  return data;
}

/**
 * Validate AI-generated workout data
 */
function validateWorkoutData(data) {
  const errors = [];

  // Check if data exists
  if (!data || typeof data !== "object") {
    return {
      isValid: false,
      errors: ["Workout data is missing or not an object"],
    };
  }

  // Check required top-level fields
  if (!data.name || typeof data.name !== "string" || data.name.trim() === "") {
    errors.push("Workout name is required and must be a non-empty string");
  }

  if (
    !data.description ||
    typeof data.description !== "string" ||
    data.description.trim() === ""
  ) {
    errors.push(
      "Workout description is required and must be a non-empty string"
    );
  }

  if (
    !data.targetMuscleGroups ||
    !Array.isArray(data.targetMuscleGroups) ||
    data.targetMuscleGroups.length === 0
  ) {
    errors.push("Target muscle groups must be a non-empty array");
  }

  if (
    typeof data.estimatedDuration !== "number" ||
    data.estimatedDuration <= 0
  ) {
    errors.push("Estimated duration must be a positive number");
  }

  if (
    !data.exercises ||
    !Array.isArray(data.exercises) ||
    data.exercises.length === 0
  ) {
    errors.push("Exercises must be a non-empty array");
  } else {
    // Validate each exercise
    data.exercises.forEach((exercise, index) => {
      if (!exercise || typeof exercise !== "object") {
        errors.push(`Exercise ${index + 1} is not a valid object`);
        return;
      }

      if (
        !exercise.name ||
        typeof exercise.name !== "string" ||
        exercise.name.trim() === ""
      ) {
        errors.push(
          `Exercise ${
            index + 1
          }: name is required and must be a non-empty string`
        );
      }

      if (
        !exercise.type ||
        typeof exercise.type !== "string" ||
        exercise.type.trim() === ""
      ) {
        errors.push(
          `Exercise ${
            index + 1
          }: type is required and must be a non-empty string`
        );
      }

      if (
        !exercise.muscleGroups ||
        !Array.isArray(exercise.muscleGroups) ||
        exercise.muscleGroups.length === 0
      ) {
        errors.push(
          `Exercise ${index + 1}: muscle groups must be a non-empty array`
        );
      }

      if (
        !exercise.instructions ||
        typeof exercise.instructions !== "string" ||
        exercise.instructions.trim() === ""
      ) {
        errors.push(
          `Exercise ${
            index + 1
          }: instructions are required and must be a non-empty string`
        );
      }

      // Check sets data
      if (
        !exercise.sets ||
        !Array.isArray(exercise.sets) ||
        exercise.sets.length === 0
      ) {
        errors.push(`Exercise ${index + 1}: sets must be a non-empty array`);
      } else {
        exercise.sets.forEach((set, setIndex) => {
          if (!set || typeof set !== "object") {
            errors.push(
              `Exercise ${index + 1}, Set ${setIndex + 1}: invalid set object`
            );
            return;
          }

          if (typeof set.reps !== "number" || set.reps <= 0) {
            errors.push(
              `Exercise ${index + 1}, Set ${
                setIndex + 1
              }: reps must be a positive number`
            );
          }

          // Weight is optional but if present must be valid
          let weight = set.weight;
          if (weight === null || weight === undefined) {
            weight = 0; // Default to bodyweight
          }
          if (typeof weight !== "number" || weight < 0) {
            errors.push(
              `Exercise ${index + 1}, Set ${
                setIndex + 1
              }: weight must be a non-negative number (got: ${typeof weight} = ${weight})`
            );
          }
        });
      }
    });
  }

  return {
    isValid: errors.length === 0,
    errors: errors,
  };
}

/**
 * Replace a specific exercise in a workout with AI-generated alternatives
 */
exports.replaceExerciseWithAI = functions.https.onCall(
  async (data, context) => {
    try {
      console.log("=== REPLACE EXERCISE WITH AI START ===");
      console.log("Data received:", JSON.stringify(data, null, 2));

      const {
        exerciseToReplace,
        targetMuscleGroups,
        availableEquipment,
        fitnessLevel,
        workoutType,
        reason, // Why user wants to replace (optional)
      } = data;

      // Validate input
      if (!exerciseToReplace || typeof exerciseToReplace !== "string") {
        console.error("Invalid exercise name:", exerciseToReplace);
        throw new functions.https.HttpsError(
          "invalid-argument",
          "Exercise to replace is required"
        );
      }

      // Check if Gemini is configured
      console.log("Checking Gemini configuration...");
      console.log("API Key exists:", !!geminiClient.apiKey);
      console.log("API Key length:", geminiClient.apiKey?.length || 0);

      if (!geminiClient.isConfigured()) {
        console.error("Gemini client is not configured");
        throw new functions.https.HttpsError(
          "failed-precondition",
          "AI service is not configured"
        );
      }

      console.log("=== EXERCISE REPLACEMENT REQUEST ===");
      console.log("Exercise to replace:", exerciseToReplace);
      console.log("Target muscles:", targetMuscleGroups);
      console.log("Available equipment:", availableEquipment);
      console.log("Reason:", reason || "Not specified");

      // Build prompt for exercise replacement
      const prompt = buildExerciseReplacementPrompt({
        exerciseToReplace,
        targetMuscleGroups,
        availableEquipment,
        fitnessLevel,
      });

      // Log token usage for monitoring (approximate token count)
      const estimatedTokens = prompt.length / 4; // Rough estimate: 4 chars per token
      console.log(`=== TOKEN USAGE ESTIMATE ===`);
      console.log(`Prompt length: ${prompt.length} characters`);
      console.log(`Estimated tokens: ${Math.round(estimatedTokens)}`);
      console.log(`Target: Under 1000 tokens`);

      // Call Gemini API with optimized settings for faster response
      console.log("=== CALLING GEMINI FOR EXERCISE REPLACEMENT ===");
      const aiResponse = await geminiClient.generateContent(prompt, {
        maxTokens: 3800, // Reduced for faster response
        temperature: 0.7, // Balanced creativity
      });

      console.log("=== AI REPLACEMENT RESPONSE ===");
      console.log("Response:", aiResponse);

      // Parse the response with fallback
      let alternativeExercises;
      try {
        console.log("=== RAW AI RESPONSE ===");
        console.log("Raw response length:", aiResponse?.length || 0);
        console.log("Raw response:", aiResponse);

        if (!aiResponse || typeof aiResponse !== "string") {
          console.error(
            "AI response is empty or not a string, providing fallback"
          );
          // Provide fallback alternatives
          alternativeExercises = createFallbackAlternatives(
            exerciseToReplace,
            targetMuscleGroups,
            availableEquipment
          );
        } else {
          const cleanResponse = aiResponse
            .replace(/```json\s*|\s*```/g, "")
            .replace(/```\s*|\s*```/g, "")
            .trim();

          console.log("=== CLEANED RESPONSE ===");
          console.log("Cleaned response:", cleanResponse);

          // Try to find valid JSON in the response
          let jsonToParse = cleanResponse;

          // Look for array brackets
          const jsonStart = cleanResponse.indexOf("[");
          const jsonEnd = cleanResponse.lastIndexOf("]") + 1;

          if (jsonStart !== -1 && jsonEnd > jsonStart) {
            jsonToParse = cleanResponse.substring(jsonStart, jsonEnd);
          } else {
            // Try to find object brackets and wrap in array
            const objStart = cleanResponse.indexOf("{");
            const objEnd = cleanResponse.lastIndexOf("}") + 1;
            if (objStart !== -1 && objEnd > objStart) {
              jsonToParse =
                "[" + cleanResponse.substring(objStart, objEnd) + "]";
            }
          }

          console.log("=== PARSING JSON ===");
          console.log("JSON to parse:", jsonToParse);

          try {
            alternativeExercises = JSON.parse(jsonToParse);
          } catch (jsonError) {
            console.error(
              "JSON Parse failed, trying to fix incomplete JSON:",
              jsonError.message
            );

            // Try to fix incomplete JSON by adding missing closing brackets
            let fixedJson = jsonToParse;
            if (!fixedJson.endsWith("]")) {
              // Count opening brackets
              const openBrackets = (fixedJson.match(/{/g) || []).length;
              const closeBrackets = (fixedJson.match(/}/g) || []).length;

              // Add missing closing brackets
              for (let i = 0; i < openBrackets - closeBrackets; i++) {
                fixedJson += "}";
              }

              if (!fixedJson.endsWith("]")) {
                fixedJson += "]";
              }
            }

            console.log("Trying to parse fixed JSON:", fixedJson);
            alternativeExercises = JSON.parse(fixedJson);
          }

          if (!Array.isArray(alternativeExercises)) {
            console.error(
              "Parsed result is not an array:",
              typeof alternativeExercises
            );
            if (
              typeof alternativeExercises === "object" &&
              alternativeExercises !== null
            ) {
              alternativeExercises = [alternativeExercises];
            } else {
              throw new Error("Response is not an array or object");
            }
          }

          if (alternativeExercises.length === 0) {
            console.error(
              "No alternatives found in response, providing fallback"
            );
            alternativeExercises = createFallbackAlternatives(
              exerciseToReplace,
              targetMuscleGroups,
              availableEquipment
            );
          }
        }

        console.log("=== PARSING SUCCESS ===");
        console.log("Found alternatives:", alternativeExercises.length);
      } catch (parseError) {
        console.error("=== PARSING FAILED ===");
        console.error("Parse error:", parseError.message);
        console.error("Error details:", parseError);

        console.log("Providing fallback alternatives due to parsing failure");
        alternativeExercises = createFallbackAlternatives(
          exerciseToReplace,
          targetMuscleGroups,
          availableEquipment
        );
      } // Clean and validate alternatives
      const cleanedAlternatives = alternativeExercises
        .map((exercise) => {
          const cleaned = cleanExerciseData(exercise);
          // Additional validation for Flutter compatibility
          if (
            cleaned &&
            cleaned.name &&
            cleaned.category &&
            cleaned.difficulty
          ) {
            // Ensure all required string fields are present and non-null
            cleaned.category = cleaned.category || "Strength";
            cleaned.movement_type = cleaned.movement_type || "Push";
            cleaned.movement_pattern = cleaned.movement_pattern || "Horizontal";
            cleaned.grip_type = cleaned.grip_type || "None";
            cleaned.range_of_motion = cleaned.range_of_motion || "Full";
            cleaned.tempo = cleaned.tempo || "Normal";
            cleaned.muscle_group = cleaned.muscle_group || "Upper Body";
            return cleaned;
          }
          return null;
        })
        .filter((exercise) => exercise !== null);

      console.log("=== EXERCISE REPLACEMENT SUCCESS ===");
      console.log("Generated alternatives:", cleanedAlternatives.length);

      return {
        originalExercise: exerciseToReplace,
        alternatives: cleanedAlternatives,
        replacementReason: reason,
        timestamp: new Date().toISOString(),
      };
    } catch (error) {
      console.error("Error in replaceExerciseWithAI:", error);
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }
      throw new functions.https.HttpsError(
        "internal",
        "Failed to generate exercise alternatives"
      );
    }
  }
);

/**
 * Get similar exercises from database based on muscle groups and equipment
 */
exports.getSimilarExercises = functions.https.onCall(async (data, context) => {
  try {
    console.log("=== GET SIMILAR EXERCISES START ===");
    console.log("Data received:", JSON.stringify(data, null, 2));

    const {
      targetMuscleGroups,
      availableEquipment,
      exerciseType,
      excludeExercises, // Array of exercise names to exclude
    } = data;

    // Validate input and provide fallbacks
    let validMuscleGroups = targetMuscleGroups;
    if (
      !targetMuscleGroups ||
      !Array.isArray(targetMuscleGroups) ||
      targetMuscleGroups.length === 0
    ) {
      console.warn("No target muscle groups provided, using fallback");
      validMuscleGroups = ["Upper Body", "Lower Body", "Core"]; // Default fallback
    }

    console.log("=== SIMILAR EXERCISES REQUEST ===");
    console.log("Target muscles:", validMuscleGroups);
    console.log("Equipment:", availableEquipment);
    console.log("Exclude:", excludeExercises);

    // Query Firestore for similar exercises
    // Note: Firestore only allows one array-contains-any per query
    // We'll prioritize muscle groups over equipment and filter equipment client-side
    console.log("=== BUILDING FIRESTORE QUERY ===");
    let query = admin.firestore().collection("exercises");

    // Primary filter: muscle groups (most important for exercise similarity)
    if (validMuscleGroups && validMuscleGroups.length > 0) {
      console.log("Adding muscle group filter:", validMuscleGroups);
      query = query.where(
        "primaryMuscles",
        "array-contains-any",
        validMuscleGroups
      );
    }

    // Filter by type if provided (exact match filter)
    if (exerciseType) {
      console.log("Adding category filter:", exerciseType);
      query = query.where("category", "==", exerciseType);
    }

    console.log("=== EXECUTING FIRESTORE QUERY ===");
    const snapshot = await query.limit(50).get(); // Get more results for client-side filtering
    console.log("Query executed, documents found:", snapshot.size);

    let exercises = [];

    if (snapshot.empty) {
      console.log(
        "No exercises found with current filters, trying broader search"
      );

      // Try without muscle group filter if no results
      let broadQuery = admin.firestore().collection("exercises");

      if (exerciseType) {
        broadQuery = broadQuery.where("category", "==", exerciseType);
      }

      const broadSnapshot = await broadQuery.limit(50).get();
      console.log("Broad query found:", broadSnapshot.size, "exercises");

      if (!broadSnapshot.empty) {
        // Process broad results
        broadSnapshot.forEach((doc) => {
          const exerciseData = doc.data();
          console.log("Processing exercise:", exerciseData.name);

          // Exclude exercises that user doesn't want
          if (
            excludeExercises &&
            excludeExercises.includes(exerciseData.name)
          ) {
            console.log("Excluding exercise:", exerciseData.name);
            return;
          }

          // Client-side filtering for equipment if specified
          if (availableEquipment && availableEquipment.length > 0) {
            const exerciseEquipment = exerciseData.equipment || [];
            const hasMatchingEquipment = exerciseEquipment.some((eq) =>
              availableEquipment.includes(eq)
            );
            if (!hasMatchingEquipment) {
              console.log("Exercise equipment mismatch:", exerciseData.name);
              return;
            }
          }

          exercises.push({
            id: doc.id,
            ...exerciseData,
          });
        });
      }
    } else {
      // Process primary results with client-side equipment filtering
      snapshot.forEach((doc) => {
        const exerciseData = doc.data();
        console.log("Processing exercise:", exerciseData.name);

        // Exclude exercises that user doesn't want
        if (excludeExercises && excludeExercises.includes(exerciseData.name)) {
          console.log("Excluding exercise:", exerciseData.name);
          return;
        }

        // Client-side filtering for equipment if specified
        if (availableEquipment && availableEquipment.length > 0) {
          const exerciseEquipment = exerciseData.equipment || [];
          const hasMatchingEquipment = exerciseEquipment.some((eq) =>
            availableEquipment.includes(eq)
          );
          if (!hasMatchingEquipment) {
            console.log("Exercise equipment mismatch:", exerciseData.name);
            return;
          }
        }

        exercises.push({
          id: doc.id,
          ...exerciseData,
        });
      });
    }

    console.log("=== SIMILAR EXERCISES FOUND ===");
    console.log("Count:", exercises.length);

    if (exercises.length === 0) {
      console.log("No exercises found, providing fallback alternatives");

      // Create fallback exercises based on target muscle groups
      const fallbackExercises = createFallbackSimilarExercises(
        validMuscleGroups,
        availableEquipment,
        excludeExercises
      );

      return {
        exercises: fallbackExercises,
        totalFound: fallbackExercises.length,
        searchCriteria: {
          targetMuscleGroups: validMuscleGroups,
          availableEquipment,
          exerciseType,
          excludeExercises,
          fallbackUsed: true,
        },
        timestamp: new Date().toISOString(),
      };
    }

    return {
      exercises: exercises.slice(0, 10), // Return top 10
      totalFound: exercises.length,
      searchCriteria: {
        targetMuscleGroups: validMuscleGroups,
        availableEquipment,
        exerciseType,
        excludeExercises,
        clientSideEquipmentFilter:
          availableEquipment && availableEquipment.length > 0,
      },
      timestamp: new Date().toISOString(),
    };
  } catch (error) {
    console.error("Error in getSimilarExercises:", error);
    console.log("Database query failed, providing fallback alternatives");

    // Provide fallback exercises when database query fails
    try {
      const fallbackExercises = createFallbackSimilarExercises(
        validMuscleGroups || targetMuscleGroups,
        availableEquipment,
        excludeExercises
      );

      return {
        exercises: fallbackExercises,
        totalFound: fallbackExercises.length,
        searchCriteria: {
          targetMuscleGroups: validMuscleGroups || targetMuscleGroups || [],
          availableEquipment: availableEquipment || [],
          exerciseType,
          excludeExercises: excludeExercises || [],
          fallbackUsed: true,
          error: "Database query failed",
        },
        timestamp: new Date().toISOString(),
      };
    } catch (fallbackError) {
      console.error("Fallback creation also failed:", fallbackError);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to find similar exercises: " + error.message
      );
    }
  }
});

/**
 * Build prompt for AI exercise replacement
 */
function buildExerciseReplacementPrompt(options) {
  const {
    exerciseToReplace,
    targetMuscleGroups,
    availableEquipment,
    fitnessLevel,
  } = options;

  // Keep token usage under 1000 with simplified prompt
  return `Replace "${exerciseToReplace}" with 3 alternatives.
Muscles: ${targetMuscleGroups?.join(", ") || "same"}
Equipment: ${availableEquipment?.join(", ") || "bodyweight"}
Level: ${fitnessLevel || "beginner"}

Return JSON array only:
[{
"id":"alt_1",
"name":"Exercise Name",
"category":"Strength",
"equipment":["Equipment"],
"muscleGroups":["Muscle"],
"difficulty":"Level",
"movementType":"Push",
"movementPattern":"Horizontal",
"gripType":"None",
"rangeOfMotion":"Full",
"tempo":"Normal",
"muscleGroup":"Upper Body",
"sets":[{"reps":12,"weight":0}],
"restTime":60
}]

Keep responses minimal. Focus on exercise name, muscles, equipment, basic sets.`;
}

/**
 * Clean and validate individual exercise data
 */
function cleanExerciseData(exercise) {
  if (!exercise || typeof exercise !== "object") {
    return null;
  }

  // Complete structure matching Flutter Exercise model requirements
  const cleaned = {
    id:
      exercise.id ||
      `alt_${Date.now()}_${Math.random().toString(36).substr(2, 5)}`,
    name: exercise.name || "Alternative Exercise",
    category: exercise.category || exercise.type || "Strength",
    equipment: Array.isArray(exercise.equipment)
      ? exercise.equipment
      : ["Bodyweight"],
    target_region: Array.isArray(exercise.muscleGroups)
      ? exercise.muscleGroups
      : ["Full Body"],
    primary_muscles: Array.isArray(exercise.muscleGroups)
      ? exercise.muscleGroups
      : ["Full Body"],
    secondary_muscles: [],
    difficulty: exercise.difficulty || "Beginner",
    movement_type: exercise.movementType || "Push",
    movement_pattern: exercise.movementPattern || "Horizontal",
    grip_type: exercise.gripType || "None",
    range_of_motion: exercise.rangeOfMotion || "Full",
    tempo: exercise.tempo || "Normal",
    muscle_group:
      exercise.muscleGroup || exercise.muscleGroups?.[0] || "Upper Body",
    muscle_info: {
      primary: Array.isArray(exercise.muscleGroups)
        ? exercise.muscleGroups
        : ["Full Body"],
      secondary: [],
      synergist: [],
      stabilizer: [],
    },
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
    restTime: typeof exercise.restTime === "number" ? exercise.restTime : 60,
  };

  // Clean sets array
  if (Array.isArray(exercise.sets) && exercise.sets.length > 0) {
    cleaned.sets = exercise.sets.map((set) => {
      if (!set || typeof set !== "object") {
        return {reps: 12, weight: 0};
      }
      return {
        reps: typeof set.reps === "number" && set.reps > 0 ? set.reps : 12,
        weight:
          typeof set.weight === "number" && set.weight >= 0 ? set.weight : 0,
      };
    });
  } else {
    cleaned.sets = [{reps: 12, weight: 0}];
  }

  return cleaned;
}

/**
 * Generate workout variations (enhanced implementation)
 */
exports.generateWorkoutVariations = functions.https.onCall(
  async (data, context) => {
    try {
      const {
        baseWorkout,
        variationType, // "easier", "harder", "different_equipment", "time_variant"
        userPreferences,
      } = data;

      console.log("=== WORKOUT VARIATIONS REQUEST ===");
      console.log("Base workout:", baseWorkout?.name);
      console.log("Variation type:", variationType);

      if (!baseWorkout || !baseWorkout.exercises) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "Base workout with exercises is required"
        );
      }

      // This would implement workout variations logic
      // For now, return a placeholder
      throw new functions.https.HttpsError(
        "unimplemented",
        "Workout variations coming soon"
      );
    } catch (error) {
      console.error("Error in generateWorkoutVariations:", error);
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }
      throw new functions.https.HttpsError(
        "internal",
        "Failed to generate workout variations"
      );
    }
  }
);

/**
 * Get AI workout suggestions (enhanced implementation)
 */
exports.getWorkoutSuggestions = functions.https.onCall(
  async (data, context) => {
    // Enhanced implementation would go here
    throw new functions.https.HttpsError(
      "unimplemented",
      "Enhanced workout suggestions coming soon"
    );
  }
);

/**
 * Create fallback alternatives when AI fails
 */
function createFallbackAlternatives(
  originalExercise,
  targetMuscleGroups,
  availableEquipment
) {
  console.log("Creating fallback alternatives for:", originalExercise);

  const fallbackExercises = [];
  const muscleGroupsArray = Array.isArray(targetMuscleGroups)
    ? targetMuscleGroups
    : [];
  const equipmentArray = Array.isArray(availableEquipment)
    ? availableEquipment
    : [];

  // Basic fallback exercises based on muscle groups
  if (
    muscleGroupsArray.includes("Chest") ||
    originalExercise.toLowerCase().includes("chest")
  ) {
    fallbackExercises.push({
      id: "fallback_1",
      name: "Push-ups",
      category: "Strength",
      equipment: ["Bodyweight"],
      target_region: ["Chest", "Triceps", "Shoulders"],
      primary_muscles: ["Chest", "Triceps", "Shoulders"],
      secondary_muscles: ["Core"],
      difficulty: "Beginner",
      movement_type: "Push",
      movement_pattern: "Horizontal",
      grip_type: "None",
      range_of_motion: "Full",
      tempo: "Normal",
      muscle_group: "Upper Body",
      muscle_info: {
        primary: ["Chest", "Triceps", "Shoulders"],
        secondary: ["Core"],
        synergist: [],
        stabilizer: [],
      },
      sets: [
        {reps: 10, weight: 0},
        {reps: 10, weight: 0},
        {reps: 10, weight: 0},
      ],
      restTime: 60,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    });
  }

  if (
    muscleGroupsArray.includes("Back") ||
    originalExercise.toLowerCase().includes("back")
  ) {
    fallbackExercises.push({
      id: "fallback_2",
      name: "Bodyweight Rows",
      category: "Strength",
      equipment: ["Bodyweight"],
      target_region: ["Back", "Biceps"],
      primary_muscles: ["Back", "Biceps"],
      secondary_muscles: ["Core"],
      difficulty: "Beginner",
      movement_type: "Pull",
      movement_pattern: "Horizontal",
      grip_type: "Pronated",
      range_of_motion: "Full",
      tempo: "Normal",
      muscle_group: "Upper Body",
      muscle_info: {
        primary: ["Back", "Biceps"],
        secondary: ["Core"],
        synergist: [],
        stabilizer: [],
      },
      sets: [
        {reps: 8, weight: 0},
        {reps: 8, weight: 0},
        {reps: 8, weight: 0},
      ],
      restTime: 60,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    });
  }

  if (
    muscleGroupsArray.includes("Legs") ||
    originalExercise.toLowerCase().includes("squat") ||
    originalExercise.toLowerCase().includes("leg")
  ) {
    fallbackExercises.push({
      id: "fallback_3",
      name: "Bodyweight Squats",
      category: "Strength",
      equipment: ["Bodyweight"],
      target_region: ["Legs", "Glutes"],
      primary_muscles: ["Legs", "Glutes"],
      secondary_muscles: ["Core"],
      difficulty: "Beginner",
      movement_type: "Push",
      movement_pattern: "Vertical",
      grip_type: "None",
      range_of_motion: "Full",
      tempo: "Normal",
      muscle_group: "Lower Body",
      muscle_info: {
        primary: ["Legs", "Glutes"],
        secondary: ["Core"],
        synergist: [],
        stabilizer: [],
      },
      sets: [
        {reps: 15, weight: 0},
        {reps: 15, weight: 0},
        {reps: 15, weight: 0},
      ],
      restTime: 45,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    });
  }

  if (
    muscleGroupsArray.includes("Arms") ||
    originalExercise.toLowerCase().includes("arm") ||
    originalExercise.toLowerCase().includes("bicep")
  ) {
    fallbackExercises.push({
      id: "fallback_4",
      name: "Pike Push-ups",
      category: "Strength",
      equipment: ["Bodyweight"],
      target_region: ["Shoulders", "Triceps"],
      primary_muscles: ["Shoulders", "Triceps"],
      secondary_muscles: ["Core"],
      difficulty: "Intermediate",
      movement_type: "Push",
      movement_pattern: "Vertical",
      grip_type: "None",
      range_of_motion: "Full",
      tempo: "Normal",
      muscle_group: "Upper Body",
      muscle_info: {
        primary: ["Shoulders", "Triceps"],
        secondary: ["Core"],
        synergist: [],
        stabilizer: [],
      },
      sets: [
        {reps: 8, weight: 0},
        {reps: 8, weight: 0},
        {reps: 8, weight: 0},
      ],
      restTime: 60,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    });
  }

  // Default fallback if no specific muscle group matched
  if (fallbackExercises.length === 0) {
    fallbackExercises.push({
      id: "fallback_default",
      name: "Burpees",
      category: "Full Body",
      equipment: ["Bodyweight"],
      target_region: ["Full Body"],
      primary_muscles: ["Full Body"],
      secondary_muscles: [],
      difficulty: "Intermediate",
      movement_type: "Compound",
      movement_pattern: "Multi-Planar",
      grip_type: "None",
      range_of_motion: "Full",
      tempo: "Fast",
      muscle_group: "Full Body",
      muscle_info: {
        primary: ["Full Body"],
        secondary: [],
        synergist: [],
        stabilizer: [],
      },
      sets: [
        {reps: 5, weight: 0},
        {reps: 5, weight: 0},
        {reps: 5, weight: 0},
      ],
      restTime: 90,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    });
  }

  console.log("Created", fallbackExercises.length, "fallback alternatives");
  return fallbackExercises.slice(0, 3); // Return up to 3 alternatives
}

/**
 * Create fallback similar exercises when database query fails
 */
function createFallbackSimilarExercises(
  targetMuscleGroups,
  availableEquipment,
  excludeExercises
) {
  console.log(
    "Creating fallback similar exercises for muscles:",
    targetMuscleGroups
  );

  const fallbackExercises = [];
  const muscleGroupsArray = Array.isArray(targetMuscleGroups)
    ? targetMuscleGroups
    : [];
  const excludeArray = Array.isArray(excludeExercises) ? excludeExercises : [];

  // Comprehensive exercise database for fallback
  const exerciseDatabase = [
    {
      id: "fb_chest_1",
      name: "Push-ups",
      primaryMuscles: ["Chest", "Triceps", "Shoulders"],
      equipment: ["Bodyweight"],
      category: "Strength",
      difficulty: "Beginner",
    },
    {
      id: "fb_chest_2",
      name: "Incline Push-ups",
      primaryMuscles: ["Chest", "Triceps"],
      equipment: ["Bodyweight"],
      category: "Strength",
      difficulty: "Beginner",
    },
    {
      id: "fb_back_1",
      name: "Bodyweight Rows",
      primaryMuscles: ["Back", "Biceps"],
      equipment: ["Bodyweight"],
      category: "Strength",
      difficulty: "Intermediate",
    },
    {
      id: "fb_back_2",
      name: "Superman",
      primaryMuscles: ["Back", "Glutes"],
      equipment: ["Bodyweight"],
      category: "Strength",
      difficulty: "Beginner",
    },
    {
      id: "fb_legs_1",
      name: "Bodyweight Squats",
      primaryMuscles: ["Legs", "Glutes", "Quadriceps"],
      equipment: ["Bodyweight"],
      category: "Strength",
      difficulty: "Beginner",
    },
    {
      id: "fb_legs_2",
      name: "Lunges",
      primaryMuscles: ["Legs", "Glutes", "Quadriceps"],
      equipment: ["Bodyweight"],
      category: "Strength",
      difficulty: "Beginner",
    },
    {
      id: "fb_shoulders_1",
      name: "Pike Push-ups",
      primaryMuscles: ["Shoulders", "Triceps"],
      equipment: ["Bodyweight"],
      category: "Strength",
      difficulty: "Intermediate",
    },
    {
      id: "fb_core_1",
      name: "Plank",
      primaryMuscles: ["Core", "Abs"],
      equipment: ["Bodyweight"],
      category: "Strength",
      difficulty: "Beginner",
    },
    {
      id: "fb_core_2",
      name: "Mountain Climbers",
      primaryMuscles: ["Core", "Shoulders"],
      equipment: ["Bodyweight"],
      category: "Cardio",
      difficulty: "Intermediate",
    },
    {
      id: "fb_arms_1",
      name: "Tricep Dips",
      primaryMuscles: ["Arms", "Triceps"],
      equipment: ["Bodyweight"],
      category: "Strength",
      difficulty: "Intermediate",
    },
  ];

  // Filter exercises based on target muscle groups
  const matchingExercises = exerciseDatabase.filter((exercise) => {
    // Check if exercise targets any of the requested muscle groups
    const hasMatchingMuscle =
      muscleGroupsArray.length === 0 ||
      muscleGroupsArray.some((targetMuscle) =>
        exercise.primaryMuscles.some(
          (exerciseMuscle) =>
            exerciseMuscle.toLowerCase().includes(targetMuscle.toLowerCase()) ||
            targetMuscle.toLowerCase().includes(exerciseMuscle.toLowerCase())
        )
      );

    // Check if exercise is not in exclude list
    const notExcluded = !excludeArray.includes(exercise.name);

    return hasMatchingMuscle && notExcluded;
  });

  console.log("Found", matchingExercises.length, "matching fallback exercises");

  // If no matches, provide general exercises
  const finalExercises =
    matchingExercises.length > 0
      ? matchingExercises
      : exerciseDatabase.slice(0, 5);

  return finalExercises.slice(0, 10); // Return up to 10 exercises
}
