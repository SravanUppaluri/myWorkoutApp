/**
 * Exercise AI Search Functions
 * Handles AI-powered exercise search and generation
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");
const cors = require("cors")({origin: true});
const geminiClient = require("./utils/gemini-client-fixed");
const prompts = require("./utils/prompts");
const validation = require("./utils/validation");

/**
 * Search for exercise information using AI
 * Called from Flutter app when no exercise is found in local database
 */
exports.searchExerciseWithAI = functions.https.onCall(async (data, context) => {
  try {
    // Validate input
    const {exerciseName} = data;

    if (!exerciseName || typeof exerciseName !== "string") {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Exercise name is required and must be a string"
      );
    }

    if (exerciseName.length < 2 || exerciseName.length > 100) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Exercise name must be between 2 and 100 characters"
      );
    }

    // Check if Gemini is configured
    if (!geminiClient.isConfigured()) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "AI service is not configured. Please contact support."
      );
    }

    // Optional: Rate limiting (check user's usage)
    if (context.auth) {
      const userDoc = await admin
        .firestore()
        .collection("users")
        .doc(context.auth.uid)
        .get();

      if (userDoc.exists) {
        const userData = userDoc.data();
        const today = new Date().toDateString();
        const dailyUsage = userData.aiSearchUsage?.[today] || 0;

        // Get daily limit from environment or default to 10 for production, 1000 for development
        const dailyLimit =
          parseInt(process.env.DAILY_AI_SEARCH_LIMIT) ||
          (process.env.NODE_ENV === "development" ? 1000 : 10);

        console.log(
          `Daily AI search usage check: ${dailyUsage}/${dailyLimit} (Environment: ${process.env.NODE_ENV})`
        );

        // Limit AI searches per day per user
        if (dailyUsage >= dailyLimit) {
          throw new functions.https.HttpsError(
            "resource-exhausted",
            `Daily AI search limit (${dailyLimit}) reached. Please try again tomorrow.`
          );
        }
      }
    }

    console.log(`AI Exercise Search: "${exerciseName}"`);

    // Generate prompt
    const prompt = prompts.buildExerciseSearchPrompt(exerciseName);

    // Call Gemini API
    const aiResponse = await geminiClient.generateContent(prompt, {
      maxTokens: 600,
      temperature: 0.3,
    });

    // Parse the response
    let exerciseData;
    try {
      const cleanResponse = aiResponse.replace(/```json\n?|\n?```/g, "").trim();
      exerciseData = JSON.parse(cleanResponse);
    } catch (parseError) {
      console.error("Failed to parse AI response:", aiResponse);
      throw new functions.https.HttpsError(
        "internal",
        "AI returned invalid format"
      );
    }

    // Check if AI returned an error response (invalid input)
    if (exerciseData.error === "not_found") {
      console.log(
        `AI rejected invalid input: "${exerciseName}" - ${exerciseData.message}`
      );
      // Return null to indicate no exercise found (don't throw error)
      return null;
    }

    // Validate the exercise data
    const validationResult = validation.validateExerciseData(exerciseData);
    if (!validationResult.isValid) {
      console.error("Validation failed:", validationResult.errors);
      // Try to sanitize the data
      exerciseData = validation.sanitizeExerciseData(exerciseData);

      // Validate again after sanitization
      const revalidationResult = validation.validateExerciseData(exerciseData);
      if (!revalidationResult.isValid) {
        throw new functions.https.HttpsError(
          "internal",
          "AI generated invalid exercise data"
        );
      }
    }

    // Enhance with metadata
    const enhancedExerciseData = {
      ...validation.sanitizeExerciseData(exerciseData),
      id: `ai_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      source: "ai_generated",
      searchQuery: exerciseName,
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
            aiSearchUsage: {
              [today]: admin.firestore.FieldValue.increment(1),
            },
          },
          {merge: true}
        );
    }

    // Optional: Save the AI-generated exercise to a special collection for review
    await admin
      .firestore()
      .collection("ai_generated_exercises")
      .doc(enhancedExerciseData.id)
      .set({
        ...enhancedExerciseData,
        userId: context.auth?.uid || null,
        timestamp: new Date(),
      });

    console.log(`Successfully generated exercise: ${exerciseData.name}`);

    return enhancedExerciseData;
  } catch (error) {
    console.error("Exercise AI Search Error:", error);

    // Re-throw HttpsError as-is
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }

    // Handle network/API errors
    if (error.code === "ENOTFOUND" || error.code === "ECONNREFUSED") {
      throw new functions.https.HttpsError(
        "unavailable",
        "AI service is temporarily unavailable"
      );
    }

    throw new functions.https.HttpsError(
      "internal",
      "An unexpected error occurred while searching for the exercise"
    );
  }
});

/**
 * Get exercise variations using AI
 * Generates variations of a given exercise
 */
exports.getExerciseVariations = functions.https.onCall(
  async (data, context) => {
    try {
      // Validate input
      const {baseExercise, count = 3} = data;

      if (!baseExercise || typeof baseExercise !== "string") {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "Base exercise name is required"
        );
      }

      if (count < 1 || count > 10) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "Count must be between 1 and 10"
        );
      }

      // Check Gemini configuration
      if (!geminiClient.isConfigured()) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "AI service is not configured"
        );
      }

      console.log(
        `AI Exercise Variations: "${baseExercise}" (${count} variations)`
      );

      // Generate prompt for variations
      const prompt = prompts.buildExerciseVariationsPrompt(baseExercise, count);

      // Call Gemini
      const aiResponse = await geminiClient.generateContent(prompt, {
        maxTokens: 800,
        temperature: 0.4, // Slightly higher for more creative variations
      });

      // Parse the response
      let variationsData;
      try {
        const cleanResponse = aiResponse
          .replace(/```json\n?|\n?```/g, "")
          .trim();
        variationsData = JSON.parse(cleanResponse);
      } catch (parseError) {
        console.error("Failed to parse variations response:", aiResponse);
        throw new functions.https.HttpsError(
          "internal",
          "AI returned invalid format for variations"
        );
      }

      // Validate the variations array
      const validationResult = validation.validateExerciseArray(variationsData);
      if (!validationResult.isValid) {
        console.error("Variations validation failed:", validationResult.errors);
        throw new functions.https.HttpsError(
          "internal",
          "AI generated invalid exercise variations"
        );
      }

      // Enhance each variation with metadata
      const enhancedVariations = variationsData.map((variation, index) => ({
        ...validation.sanitizeExerciseData(variation),
        id: `ai_var_${Date.now()}_${index}_${Math.random()
          .toString(36)
          .substr(2, 9)}`,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        source: "ai_generated_variation",
        baseExercise: baseExercise,
      }));

      console.log(
        `Successfully generated ${enhancedVariations.length} exercise variations`
      );

      return enhancedVariations;
    } catch (error) {
      console.error("Exercise Variations Error:", error);

      if (error instanceof functions.https.HttpsError) {
        throw error;
      }

      throw new functions.https.HttpsError(
        "internal",
        "Failed to generate exercise variations"
      );
    }
  }
);
