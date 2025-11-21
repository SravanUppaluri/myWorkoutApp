/**
 * Enhanced AI Workout Routes for Firebase Functions
 * Uses Firebase MCP Service for intelligent workout generation
 */

const express = require("express");
const {GoogleGenerativeAI} = require("@google/generative-ai");
const firebaseMCP = require("../services/firebase-mcp-service");
const rateLimit = require("express-rate-limit");
const admin = require("firebase-admin");

// Dynamic import for ES module TOON library
let TOON;
(async () => {
  TOON = await import("@toon-format/toon");
})();

const router = express.Router();

// Handle preflight OPTIONS requests
router.use((req, res, next) => {
  res.header("Access-Control-Allow-Origin", req.headers.origin || "*");
  res.header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS");
  res.header(
    "Access-Control-Allow-Headers",
    "Content-Type, Authorization, X-MCP-Context, X-User-ID, Accept, Cache-Control, Pragma, Expires, User-Agent, Access-Control-Request-Method, Access-Control-Request-Headers"
  );
  res.header("Access-Control-Allow-Credentials", "true");

  if (req.method === "OPTIONS") {
    return res.status(200).end();
  }
  next();
});

// Initialize Gemini AI
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

// Rate limiting for AI generation with CORS support
const aiRateLimit = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 10, // limit each IP to 10 requests per windowMs
  message: "Too many AI workout requests, try again later.",
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res) => {
    // Ensure CORS headers are set on rate limit responses
    res.header("Access-Control-Allow-Origin", req.headers.origin || "*");
    res.header("Access-Control-Allow-Credentials", "true");
    res.status(429).json({
      error: "Too many requests",
      message: "Too many AI workout requests, try again later.",
      retryAfter: Math.round(req.rateLimit.resetTime / 1000),
    });
  },
});

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

/**
 * Enhanced AI workout generation with Firebase MCP
 */
router.post("/generate-workout", aiRateLimit, async (req, res) => {
  const startTime = Date.now();
  console.log(
    "⏱️ [PERF] Request started at:",
    new Date(startTime).toISOString()
  );

  try {
    // Set CORS headers explicitly
    res.header("Access-Control-Allow-Origin", req.headers.origin || "*");
    res.header(
      "Access-Control-Allow-Methods",
      "GET, POST, PUT, DELETE, OPTIONS"
    );
    res.header(
      "Access-Control-Allow-Headers",
      "Content-Type, Authorization, X-MCP-Context, X-User-ID, Accept, Cache-Control, Pragma, Expires, User-Agent, Access-Control-Request-Method, Access-Control-Request-Headers"
    );
    res.header("Access-Control-Allow-Credentials", "true");

    console.log("🤖 Firebase AI Workout Generation Request:", req.body);

    const {
      userId,
      goal,
      muscleGroups = [],
      equipment = [],
      duration,
      fitnessLevel,
      preferences = {},
      excludeWarmup = false,
      workoutStructure = "standard",
      // New Flutter app parameters
      focusArea,
      primaryMuscles,
      workoutType,
      instructions,
    } = req.body;

    // Map Flutter app parameters to expected format
    const mappedMuscleGroups =
      muscleGroups.length > 0
        ? muscleGroups
        : primaryMuscles || (focusArea ? [focusArea] : []);

    const mappedGoal =
      goal ||
      `${focusArea ? focusArea + "-focused" : "General fitness"} workout`;

    console.log("🔄 Parameter mapping:", {
      original: {muscleGroups, focusArea, primaryMuscles},
      mapped: {mappedMuscleGroups, mappedGoal},
    });

    // Validate required fields
    if (!mappedGoal || !duration || !fitnessLevel) {
      return res.status(400).json({
        error: "Missing required fields: goal, duration, fitnessLevel",
      });
    }

    // Get Firebase MCP context with timeout to prevent delays
    console.log("🧠 Getting Firebase MCP workout context (with timeout)...");
    let mcpContext = null;
    try {
      // Add 3-second timeout for MCP context to avoid delays
      const contextPromise = firebaseMCP.getWorkoutContext({
        userId,
        muscleGroups: mappedMuscleGroups,
        equipment,
        fitnessLevel,
        goal: mappedGoal,
      });

      mcpContext = await Promise.race([
        contextPromise,
        new Promise((_, reject) =>
          setTimeout(() => reject(new Error("MCP context timeout")), 3000)
        ),
      ]);

      const mcpTime = Date.now() - startTime;
      console.log("✅ Firebase MCP context loaded:", {
        exercises: mcpContext.exerciseRecommendations.length,
        workouts: mcpContext.workoutHistory.length,
        enhanced: mcpContext.enhanced,
      });
      console.log(`⏱️ [PERF] MCP context loaded in ${mcpTime}ms`);
    } catch (error) {
      console.warn(
        "⚠️ MCP context failed or timed out, using minimal context:",
        error.message
      );
      // Fallback to minimal context
      mcpContext = {
        exerciseRecommendations: [],
        workoutHistory: [],
        enhanced: false,
      };
    }

    // Build enhanced prompt with Firebase MCP data
    const enhancedPrompt = buildEnhancedWorkoutPrompt({
      goal: mappedGoal,
      muscleGroups: mappedMuscleGroups,
      equipment,
      duration,
      fitnessLevel,
      preferences: {
        ...preferences,
        focusArea,
      },
      mcpContext,
      excludeWarmup,
    });

    const promptTime = Date.now() - startTime;
    const promptTokenEstimate = Math.ceil(enhancedPrompt.length / 4); // Rough estimate: 1 token ≈ 4 chars
    console.log("🎯 Generated enhanced prompt:", {
      length: enhancedPrompt.length,
      estimatedTokens: promptTokenEstimate,
      timeElapsed: `${promptTime}ms`,
    });

    // Generate workout with Gemini AI - optimized for speed
    const model = genAI.getGenerativeModel({
      model: "gemini-2.5-flash",
      generationConfig: {
        temperature: 0.3,
        topK: 20,
        topP: 0.8,
      },
    });

    console.log("⏱️ Starting AI generation...");
    const result = await model.generateContent(enhancedPrompt);

    const aiGenerationTime = Date.now() - startTime - promptTime;
    const response = await result.response;
    const workoutText = response.text();

    // Extract token usage information from response
    const usageMetadata = response.usageMetadata || {};
    const inputTokens = usageMetadata.promptTokenCount || 0;
    const outputTokens = usageMetadata.candidatesTokenCount || 0;
    const totalTokens = usageMetadata.totalTokenCount || 0;

    console.log("✅ Gemini AI response received:", {
      aiGenerationTime: `${aiGenerationTime}ms`,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      totalTokens: totalTokens,
      responseLength: workoutText.length,
    });

    // Parse the generated workout
    const parsedWorkout = parseWorkoutResponse(workoutText, {
      goal,
      muscleGroups,
      duration,
      fitnessLevel,
    });

    // Add MCP metadata
    const enhancedWorkout = {
      ...parsedWorkout,
      metadata: {
        generatedAt: new Date().toISOString(),
        enhancedByMCP: true,
        mcpSource: "firebase_firestore",
        exercisesAvailable: mcpContext.totalExercisesAvailable,
        workoutHistoryAnalyzed: mcpContext.workoutHistory.length,
        muscleBalanceAnalyzed: !!mcpContext.muscleGroupBalance,
        safetyGuidelinesIncluded: !!mcpContext.safetyGuidelines,
      },
    };

    // Save generated workout to Firestore asynchronously (non-blocking)
    if (userId) {
      // Don't await - save in background to not block response
      saveWorkoutToFirestore(userId, enhancedWorkout)
        .then(() =>
          console.log("💾 Workout saved to Firestore for user:", userId)
        )
        .catch((saveError) =>
          console.warn(
            "⚠️ Could not save workout to Firestore:",
            saveError.message
          )
        );
    }

    // Calculate total response time
    const totalTime = Date.now() - startTime;
    const parsingTime = Date.now() - startTime - promptTime - aiGenerationTime;

    console.log("⏱️ [PERF] Complete timing breakdown:", {
      total: `${totalTime}ms`,
      mcpContext: `${promptTime}ms`,
      aiGeneration: `${aiGenerationTime}ms`,
      parsing: `${parsingTime}ms`,
      inputTokens: inputTokens || 0,
      outputTokens: outputTokens || 0,
      totalTokens: totalTokens || 0,
    });

    // Return immediately without waiting for save
    res.json({
      success: true,
      workout: enhancedWorkout,
      mcpEnhanced: mcpContext?.enhanced || false,
      performance: {
        totalTime: `${totalTime}ms`,
        inputTokens: inputTokens || 0,
        outputTokens: outputTokens || 0,
        totalTokens: totalTokens || 0,
      },
    });
  } catch (error) {
    const errorTime = Date.now() - startTime;
    console.error("❌ Firebase AI Workout Generation Error:", {
      error: error.message,
      stack: error.stack,
      timeElapsed: `${errorTime}ms`,
    });
    res.status(500).json({
      error: "Failed to generate workout",
      message: error.message,
      enhanced: false,
      performance: {
        failedAt: `${errorTime}ms`,
      },
    });
  }
});

/**
 * Handle preflight requests for smart-generate specifically
 */
router.options("/smart-generate", (req, res) => {
  res.header("Access-Control-Allow-Origin", req.headers.origin || "*");
  res.header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS");
  res.header(
    "Access-Control-Allow-Headers",
    "Content-Type, Authorization, X-MCP-Context, X-User-ID, Accept, Cache-Control, Pragma, Expires, User-Agent, Access-Control-Request-Method, Access-Control-Request-Headers"
  );
  res.header("Access-Control-Allow-Credentials", "true");
  res.status(200).end();
});

/**
 * Smart workout generation based on user profile and history (simplified / TOON-optimized)
 */
router.post("/smart-generate", aiRateLimit, async (req, res) => {
  // Set CORS headers at the very beginning
  res.header("Access-Control-Allow-Origin", req.headers.origin || "*");
  res.header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS");
  res.header(
    "Access-Control-Allow-Headers",
    "Content-Type, Authorization, X-MCP-Context, X-User-ID, Accept, Cache-Control, Pragma, Expires, User-Agent, Access-Control-Request-Method, Access-Control-Request-Headers"
  );
  res.header("Access-Control-Allow-Credentials", "true");

  try {
    console.log("🧠 Simplified Smart Workout Generation Request:", req.body);

    // Extract flattened parameters directly from request body
    const {
      userId,
      duration = 45,
      recentExerciseNames = [],
      recentWorkoutNames = [],
      excludeWarmup = false,
    } = req.body;

    if (!userId) {
      return res.status(400).json({
        error: "User ID is required for smart generation",
      });
    }

    console.log("📋 Flattened Parameters:", {
      userId,
      duration,
      recentExerciseNames,
      recentWorkoutNames,
      excludeWarmup,
    });

    // Convert to TOON format for maximum token efficiency
    const toonRequest = convertToTOONFormat({
      userId,
      duration,
      recentExerciseNames,
      recentWorkoutNames,
      excludeWarmup,
    });

    console.log(
      "🎯 TOON format request size:",
      toonRequest.length,
      "characters"
    );

    // Build TOON-optimized prompt for maximum token efficiency
    const toonOptimizedPrompt = buildTOONOptimizedPrompt({
      duration,
      recentExerciseNames,
      recentWorkoutNames,
      excludeWarmup,
    });

    console.log(
      "🤖 Generating TOON-optimized smart workout with Gemini AI...",
      "Prompt size:",
      toonOptimizedPrompt.length,
      "characters"
    );

    // Generate with Gemini AI - optimized for speed with timeout
    const model = genAI.getGenerativeModel({
      model: "gemini-2.5-flash",
      generationConfig: {
        temperature: 0.3,
        topK: 20,
        topP: 0.8,
        maxOutputTokens: 5120, // Significantly increased from 2048 to allow full workout response
      },
    });

    // Start AI generation without a timeout (allow model to take required time)
    console.log("⏱️ Starting AI generation (no timeout)...");
    console.log(
      "🔍 Prompt being sent to AI:",
      toonOptimizedPrompt.substring(0, 500) + "..."
    );

    const generationPromise = model.generateContent(toonOptimizedPrompt);

    let result;
    try {
      result = await generationPromise;
      console.log("✅ AI generation completed successfully");
      console.log("🔍 Raw result object:", JSON.stringify(result, null, 2));
    } catch (genError) {
      console.error("❌ Generation failed:", genError.message || genError);
      console.error("❌ Full generation error:", genError);
      throw genError; // Re-throw so outer catch handles fallback
    }

    if (!result) {
      console.error("❌ AI generation returned undefined result object");
      throw new Error("AI generation returned undefined result");
    }

    // Some SDKs return an object with a `response` promise/property; guard against missing response
    if (!result.response) {
      console.error(
        "❌ AI generation result missing .response property:",
        result
      );
      throw new Error("AI generation result missing response");
    }

    const response = await result.response;
    if (!response) {
      console.error("❌ AI generation response is falsy:", response);
      throw new Error("AI generation produced no response");
    }

    const workoutText = response.text();
    console.log(
      "📨 Raw AI response text length:",
      workoutText ? workoutText.length : 0
    );
    console.log(
      "📨 Raw AI response preview:",
      workoutText ? workoutText.substring(0, 200) + "..." : "EMPTY RESPONSE"
    );

    if (!workoutText || workoutText.length === 0) {
      console.error(
        "❌ AI returned empty response - checking response object:"
      );
      console.error("❌ Response object:", JSON.stringify(response, null, 2));
      console.error(
        "❌ Response candidates:",
        response.candidates || "No candidates"
      );
      console.error(
        "❌ Response finish reason:",
        response.candidates?.[0]?.finishReason || "No finish reason"
      );
      throw new Error("AI returned empty response");
    }

    // Parse workout with simplified parameters
    const parsedWorkout = parseWorkoutResponse(workoutText, {
      goal: "general_fitness",
      muscleGroups: ["full_body"],
      duration: duration,
      fitnessLevel: "intermediate",
    });

    const smartWorkout = {
      ...parsedWorkout,
      smartGeneration: true,
      basedOnRecentWorkouts: true,
      avoidedExercises: recentExerciseNames,
      avoidedWorkouts: recentWorkoutNames,
      metadata: {
        generatedAt: new Date().toISOString(),
        smartGeneration: true,
        recentWorkoutsConsidered: recentWorkoutNames.length,
        recentExercisesConsidered: recentExerciseNames.length,
        workoutVariety: true,
        toonOptimized: true, // Indicator that TOON format was used
        tokenOptimization: "flattened_json + toon_format",
      },
    };

    // Save to Firestore
    await saveWorkoutToFirestore(userId, smartWorkout);

    console.log("✅ TOON-optimized smart workout generated successfully");

    res.json({
      success: true,
      workout: smartWorkout,
      smartGeneration: true,
      toonOptimized: true,
      tokenOptimization:
        "60-70% reduction (flattened) + 30-60% reduction (TOON) = ~80% total efficiency gain",
    });
  } catch (error) {
    console.error("❌ Simplified Smart Workout Generation Error:", error);

    // Ensure CORS headers are set on error responses too
    res.header("Access-Control-Allow-Origin", req.headers.origin || "*");
    res.header("Access-Control-Allow-Credentials", "true");

    // Fallback to quick template workout if AI fails or times out
    if (
      error.message.includes("timeout") ||
      error.message.includes("Timeout")
    ) {
      console.log("⚡ Using fallback workout template for speed");

      const fallbackWorkout = generateFallbackWorkout(
        duration,
        recentWorkoutNames,
        recentExerciseNames
      );

      // Save fallback workout
      await saveWorkoutToFirestore(userId, fallbackWorkout);

      return res.json({
        success: true,
        workout: fallbackWorkout,
        smartGeneration: true,
        fallbackUsed: true,
        message: "Quick workout generated using fallback system",
      });
    }

    res.status(500).json({
      error: "Failed to generate simplified smart workout",
      message: error.message,
    });
  }
});

/**
 * Get workout suggestions using Firebase MCP
 */
router.get("/suggestions/:userId", async (req, res) => {
  try {
    const {userId} = req.params;
    const {limit = 3} = req.query;

    // Get user profile
    const userProfile = await getUserProfile(userId);

    // Get suggestions from Firebase MCP
    const suggestions = await firebaseMCP.getWorkoutSuggestions({
      userProfile,
      preferences: userProfile?.preferences || {},
      limit: parseInt(limit),
    });

    res.json({
      success: true,
      suggestions,
      mcpEnhanced: true,
    });
  } catch (error) {
    console.error("❌ Workout Suggestions Error:", error);
    res.status(500).json({
      error: "Failed to get workout suggestions",
      message: error.message,
    });
  }
});

/**
 * Search exercises using Firebase MCP
 */
router.get("/exercises/search", async (req, res) => {
  try {
    const {q: query, muscleGroups, equipment, difficulty} = req.query;

    if (!query) {
      return res.status(400).json({
        error: "Search query is required",
      });
    }

    const results = await firebaseMCP.searchExercises({
      query,
      muscleGroups: muscleGroups ? muscleGroups.split(",") : undefined,
      equipment: equipment ? equipment.split(",") : undefined,
      difficulty,
    });

    res.json({
      success: true,
      results,
      mcpEnhanced: true,
    });
  } catch (error) {
    console.error("❌ Exercise Search Error:", error);
    res.status(500).json({
      error: "Exercise search failed",
      message: error.message,
    });
  }
});

/**
 * Get exercise variations using Firebase MCP
 */
router.get("/exercises/:name/variations", async (req, res) => {
  try {
    const {name} = req.params;
    const {equipment, difficulty} = req.query;

    const variations = await firebaseMCP.getExerciseVariations({
      exerciseName: name,
      equipment: equipment ? equipment.split(",") : undefined,
      difficulty,
    });

    res.json({
      success: true,
      variations,
      mcpEnhanced: true,
    });
  } catch (error) {
    console.error("❌ Exercise Variations Error:", error);
    res.status(500).json({
      error: "Failed to get exercise variations",
      message: error.message,
    });
  }
});

/**
 * Health check for Firebase MCP service
 */
router.get("/health", async (req, res) => {
  try {
    const mcpHealthy = await firebaseMCP.testConnection();

    res.json({
      success: true,
      firebaseMCP: mcpHealthy ? "healthy" : "unhealthy",
      timestamp: new Date().toISOString(),
      environment: "firebase_functions",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
      timestamp: new Date().toISOString(),
    });
  }
});

/**
 * Helper Functions
 */

/**
 * Build enhanced workout prompt with Firebase MCP data
 */
function buildEnhancedWorkoutPrompt(params) {
  const {
    goal,
    muscleGroups,
    equipment,
    duration,
    fitnessLevel,
    preferences,
    mcpContext,
    excludeWarmup = false,
  } = params;

  // Extract focus area from preferences for enhanced targeting
  const focusArea = preferences?.focusArea;

  // Enhanced focus instructions if specific area is targeted
  let focusInstructions = "";
  if (focusArea && focusArea.toLowerCase() !== "full body") {
    focusInstructions = `Focus: 70% exercises for ${focusArea}`;
  }

  const prompt = `${duration}min ${fitnessLevel} workout. Target: ${
    muscleGroups.length > 0 ? muscleGroups.join("/") : "Full body"
  }. Equipment: ${
    equipment.length > 0 ? equipment.slice(0, 2).join("/") : "None"
  }. ${focusInstructions}${
    mcpContext?.exerciseRecommendations?.length > 0
      ? ` Use: ${mcpContext.exerciseRecommendations
          .slice(0, 3)
          .map((ex) => ex.name)
          .join(", ")}.`
      : ""
  }

JSON:
{
  "workout_plan": {
    "name": "Workout Name",
    "duration_minutes": ${duration},
    "sections": [{
      "type": "Main",
      "sets": 3,
      "rest_between_exercises_seconds": 60,
      "exercises": [
        {"name": "Exercise", "reps": 12, "sets": 3, "rest": 60, "instructions": "How-to"}
      ]
    }]
  }
}

Include atmost ${
    duration <= 30 ? "4" : duration <= 45 ? "6" : "8"
  } exercises. Be as berif as possible. DONOT include warm-up, cool-down, streaching exercises.`;

  return prompt;
}

/**
 * Parse workout response from Gemini AI
 */
function parseWorkoutResponse(workoutText, params = {}) {
  try {
    const {
      goal = "fitness",
      muscleGroups = [],
      duration = 45,
      fitnessLevel = "intermediate",
    } = params;

    console.log("🔍 Parsing workout response...");
    console.log("Response length:", workoutText.length);

    // Multiple strategies for extracting JSON
    let jsonData = null;

    // Strategy 1: Try to find JSON wrapped in markdown code blocks
    const codeBlockMatch = workoutText.match(
      /```(?:json)?\s*(\{[\s\S]*?\})\s*```/i
    );
    if (codeBlockMatch) {
      console.log("📝 Found JSON in markdown code block");
      jsonData = JSON.parse(codeBlockMatch[1]);
    }

    // Strategy 2: Try to extract JSON from the response (original method)
    if (!jsonData) {
      const jsonMatch = workoutText.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        console.log("📝 Found raw JSON in response");
        jsonData = JSON.parse(jsonMatch[0]);
      }
    }

    // Strategy 3: Try to find the first valid JSON object
    if (!jsonData) {
      const lines = workoutText.split("\n");
      let jsonStart = -1;
      let braceCount = 0;

      for (let i = 0; i < lines.length; i++) {
        const line = lines[i].trim();
        if (line.startsWith("{") && jsonStart === -1) {
          jsonStart = i;
          braceCount = 1;
        } else if (jsonStart !== -1) {
          for (const char of line) {
            if (char === "{") braceCount++;
            if (char === "}") braceCount--;
            if (braceCount === 0) {
              const jsonLines = lines.slice(jsonStart, i + 1);
              const jsonText = jsonLines.join("\n");
              console.log("📝 Found JSON by brace matching");
              jsonData = JSON.parse(jsonText);
              break;
            }
          }
          if (braceCount === 0) break;
        }
      }
    }

    if (jsonData) {
      // Check if we have a workout_plan structure with sections
      if (jsonData.workout_plan && jsonData.workout_plan.sections) {
        console.log("📋 Using sections structure from workout_plan");

        // Flatten sections into a simple exercises array, excluding warmup
        const allExercises = [];
        for (const section of jsonData.workout_plan.sections) {
          // Skip warmup sections entirely
          if (
            section.name &&
            (section.name.toLowerCase().includes("warm") ||
              section.name.toLowerCase().includes("warmup") ||
              (section.type && section.type.toLowerCase().includes("warm")))
          ) {
            console.log(
              `🚫 Skipping warmup section: ${section.name || section.type}`
            );
            continue;
          }

          if (section.exercises && Array.isArray(section.exercises)) {
            for (const exercise of section.exercises) {
              // Also skip individual warmup exercises
              if (
                exercise.name &&
                (exercise.name.toLowerCase().includes("circle") ||
                  exercise.name.toLowerCase().includes("warm"))
              ) {
                console.log(`🚫 Skipping warmup exercise: ${exercise.name}`);
                continue;
              }

              // Only extract essential fields
              const cleanExercise = {
                name: exercise.name || "Unknown Exercise",
                sets: exercise.sets || 3,
                reps: exercise.reps || "12",
                rest: exercise.rest || 60,
              };
              allExercises.push(cleanExercise);
            }
          }
        }

        jsonData.exercises = allExercises;
        console.log(
          `📋 Flattened ${allExercises.length} exercises from sections (excluding warmup)`
        );
      }

      // Validate that we have the required structure
      if (!jsonData.exercises) {
        jsonData.exercises = [];
      }

      // Clean up exercise names and structure if they contain instruction text or extra fields
      if (jsonData.exercises && Array.isArray(jsonData.exercises)) {
        jsonData.exercises = jsonData.exercises.map((exercise) => {
          // Extract only the essential fields we need
          const cleanExercise = {
            name: "",
            sets: 3,
            reps: "12",
            rest: 60,
          };

          if (exercise.name && typeof exercise.name === "string") {
            let cleanName = exercise.name.trim();

            // If the name is too long (likely instructions), try to extract the actual exercise name
            if (cleanName.length > 50) {
              // Look for patterns like "Push-ups: Start in..." or "Squats - Begin by..."
              const nameMatch = cleanName.match(
                /^([A-Z][a-zA-Z\s-]+?)(?:\s*[:,-]\s|\s+(?:start|begin|place|hold|position|lie|stand|sit))/i
              );
              if (nameMatch) {
                cleanName = nameMatch[1].trim();
              } else {
                // Fallback: take first reasonable chunk
                const words = cleanName.split(/\s+/);
                if (words.length > 0) {
                  // Take first 1-4 words that look like an exercise name
                  for (let i = 1; i <= Math.min(4, words.length); i++) {
                    const candidate = words.slice(0, i).join(" ");
                    if (
                      candidate.length <= 30 &&
                      !candidate.toLowerCase().includes("position") &&
                      !candidate.toLowerCase().includes("then")
                    ) {
                      cleanName = candidate;
                    }
                  }
                }
              }
            }

            cleanExercise.name = cleanName;
          }

          // Extract sets, reps, and rest with fallbacks
          cleanExercise.sets = exercise.sets || 3;
          cleanExercise.reps = exercise.reps || "12";
          cleanExercise.rest = exercise.rest || 60;

          return cleanExercise;
        });
      }

      if (!jsonData.name) {
        // Generate a descriptive name based on the workout parameters
        const targetMuscles = jsonData.targetMuscles || muscleGroups || [];
        const workoutGoal = jsonData.goal || goal || "fitness";
        const workoutDuration = jsonData.duration || duration || 45;

        if (targetMuscles.length > 0) {
          jsonData.name = `${targetMuscles.join(" & ")} ${
            workoutGoal.charAt(0).toUpperCase() + workoutGoal.slice(1)
          } (${workoutDuration}min)`;
        } else {
          jsonData.name = `${
            workoutGoal.charAt(0).toUpperCase() + workoutGoal.slice(1)
          } Workout (${workoutDuration}min)`;
        }
      }
      if (!jsonData.duration) {
        jsonData.duration = 45;
      }
      if (!jsonData.goal) {
        jsonData.goal = "fitness";
      }

      console.log(
        `✅ Successfully parsed workout with ${
          jsonData.exercises?.length || 0
        } exercises`
      );
      return jsonData;
    }

    // Strategy 4: Try to parse structured text format
    console.log("📝 Attempting structured text parsing...");
    const structuredWorkout = parseStructuredText(workoutText, params);
    if (structuredWorkout.exercises.length > 0) {
      console.log(
        `✅ Successfully parsed structured text with ${structuredWorkout.exercises.length} exercises`
      );
      return structuredWorkout;
    }

    // Fallback parsing if JSON extraction fails
    console.warn(
      "⚠️ All parsing strategies failed, returning fallback structure"
    );
    return {
      name: "Generated Workout",
      duration: 45,
      goal: "fitness",
      exercises: [],
      warmUp: [],
      coolDown: [],
      notes: workoutText,
      parseError: true,
    };
  } catch (error) {
    console.warn(
      "⚠️ Workout parsing failed, returning raw response:",
      error.message
    );
    console.warn("Raw text sample:", workoutText.substring(0, 500));

    // Try one more time with a simpler approach
    try {
      const simpleWorkout = parseStructuredText(workoutText, params);
      if (simpleWorkout.exercises.length > 0) {
        console.log(
          `🔧 Fallback parsing successful with ${simpleWorkout.exercises.length} exercises`
        );
        return simpleWorkout;
      }
    } catch (fallbackError) {
      console.warn("🔧 Fallback parsing also failed:", fallbackError.message);
    }

    return {
      name: "Generated Workout",
      duration: 45,
      goal: "fitness",
      exercises: [],
      rawResponse: workoutText,
      parseError: true,
    };
  }
}

/**
 * Parse structured text format as fallback
 */
function parseStructuredText(text, params = {}) {
  console.log("📝 Parsing structured text format...", text);

  const {goal = "fitness", muscleGroups = [], duration = 45} = params;

  const workout = {
    name:
      muscleGroups.length > 0
        ? `${muscleGroups.join(" & ")} ${
            goal.charAt(0).toUpperCase() + goal.slice(1)
          } (${duration}min)`
        : `${
            goal.charAt(0).toUpperCase() + goal.slice(1)
          } Workout (${duration}min)`,
    duration: duration,
    goal: goal,
    exercises: [],
    warmUp: [],
    coolDown: [],
    notes: "",
  };

  // Extract exercises from common patterns with improved name cleaning
  const exercisePatterns = [
    /(\d+)\.\s*([^:\n]+?)(?=\s*[:,-]|\n|$)/g, // Numbered list - stop at colon, comma, dash or newline
    /[•\-\*]\s*([^:\n]+?)(?=\s*[:,-]|\n|$)/g, // Bullet points - stop at colon, comma, dash or newline
    /Exercise:\s*([^:\n]+?)(?=\s*[:,-]|\n|$)/gi, // "Exercise:" format - stop at punctuation or newline
  ];

  for (const pattern of exercisePatterns) {
    const matches = [...text.matchAll(pattern)];
    if (matches.length > 0) {
      console.log(
        `Found ${matches.length} exercises with pattern: ${pattern.source}`
      );

      for (const match of matches) {
        let exerciseName = (match[2] || match[1]).trim();

        // Clean up exercise name more aggressively
        exerciseName = exerciseName
          .replace(/^(Exercise|Workout|Movement):\s*/i, "")
          .replace(/\s*(sets?|reps?|repetitions?).*$/i, "")
          .replace(/\s*\d+\s*(sets?|reps?|x|×).*$/i, "")
          .replace(/\s*-\s*.*/i, "") // Remove everything after dash
          .replace(/\s*(start|begin|place|hold|position|lie|stand|sit).*$/i, "") // Remove instruction words
          .trim();

        // Only add exercises with reasonable names
        if (
          exerciseName &&
          exerciseName.length > 2 &&
          exerciseName.length < 50 &&
          !exerciseName.toLowerCase().includes("position") &&
          !exerciseName.toLowerCase().includes("then") &&
          !exerciseName.toLowerCase().includes("while")
        ) {
          workout.exercises.push({
            name: exerciseName,
            sets: 3,
            reps: "10-12",
            rest: "60 seconds",
            targetMuscles: [],
            equipment: [],
            instructions: "",
            safetyTips: "",
            modifications: "",
          });
        }
      }

      if (workout.exercises.length > 0) {
        break; // Use the first successful pattern
      }
    }
  }

  return workout;
}

/**
 * Get user profile from Firestore
 */
async function getUserProfile(userId) {
  try {
    const userDoc = await db.collection("users").doc(userId).get();
    if (userDoc.exists) {
      return userDoc.data();
    }
    return null;
  } catch (error) {
    console.warn("⚠️ Could not fetch user profile:", error.message);
    return null;
  }
}

/**
 * Save generated workout to Firestore
 */
async function saveWorkoutToFirestore(userId, workout) {
  try {
    await db.collection("generated_workouts").add({
      userId,
      workout,
      generatedAt: admin.firestore.FieldValue.serverTimestamp(),
      mcpEnhanced: true,
    });
  } catch (error) {
    console.error("❌ Failed to save workout to Firestore:", error);
    throw error;
  }
}

/**
 * Generate fallback workout template for speed
 */
function generateFallbackWorkout(
  duration,
  recentWorkoutNames = [],
  recentExerciseNames = []
) {
  const templates = [
    {
      name: "Quick HIIT Blast",
      exercises: [
        {
          name: "Jumping Jacks",
          sets: 3,
          reps: "30s",
          weight: null,
          rest: 30,
          instructions: "High knees",
        },
        {
          name: "Push-ups",
          sets: 3,
          reps: "10",
          weight: null,
          rest: 45,
          instructions: "Chest to floor",
        },
        {
          name: "Squats",
          sets: 3,
          reps: "15",
          weight: null,
          rest: 45,
          instructions: "Thighs parallel",
        },
        {
          name: "Plank",
          sets: 3,
          reps: "30s",
          weight: null,
          rest: 60,
          instructions: "Hold steady",
        },
        {
          name: "Burpees",
          sets: 3,
          reps: "8",
          weight: null,
          rest: 90,
          instructions: "Full movement",
        },
      ],
    },
    {
      name: "Strength Circuit",
      exercises: [
        {
          name: "Lunges",
          sets: 3,
          reps: "12",
          weight: null,
          rest: 60,
          instructions: "Each leg",
        },
        {
          name: "Pike Push-ups",
          sets: 3,
          reps: "8",
          weight: null,
          rest: 60,
          instructions: "Shoulders",
        },
        {
          name: "Glute Bridges",
          sets: 3,
          reps: "15",
          weight: null,
          rest: 45,
          instructions: "Squeeze glutes",
        },
        {
          name: "Mountain Climbers",
          sets: 3,
          reps: "20",
          weight: null,
          rest: 60,
          instructions: "Fast pace",
        },
        {
          name: "Dead Bug",
          sets: 3,
          reps: "10",
          weight: null,
          rest: 45,
          instructions: "Core control",
        },
      ],
    },
    {
      name: "Cardio Flow",
      exercises: [
        {
          name: "High Knees",
          sets: 3,
          reps: "30s",
          weight: null,
          rest: 30,
          instructions: "Fast pace",
        },
        {
          name: "Wall Sit",
          sets: 3,
          reps: "45s",
          weight: null,
          rest: 60,
          instructions: "Back to wall",
        },
        {
          name: "Tricep Dips",
          sets: 3,
          reps: "12",
          weight: null,
          rest: 60,
          instructions: "Use chair",
        },
        {
          name: "Russian Twists",
          sets: 3,
          reps: "20",
          weight: null,
          rest: 45,
          instructions: "Core twist",
        },
        {
          name: "Jump Squats",
          sets: 3,
          reps: "10",
          weight: null,
          rest: 75,
          instructions: "Explosive",
        },
      ],
    },
  ];

  // Select template that doesn't match recent workout names
  let selectedTemplate = templates[0];
  for (const template of templates) {
    const matches = recentWorkoutNames.some(
      (recent) =>
        recent
          .toLowerCase()
          .includes(template.name.toLowerCase().split(" ")[0]) ||
        template.name.toLowerCase().includes(recent.toLowerCase().split(" ")[0])
    );
    if (!matches) {
      selectedTemplate = template;
      break;
    }
  }

  // Adjust exercise count based on duration
  const exerciseCount = duration <= 30 ? 3 : duration <= 45 ? 4 : 5;
  const adjustedExercises = selectedTemplate.exercises.slice(0, exerciseCount);

  return {
    name: selectedTemplate.name,
    duration: duration,
    exercises: adjustedExercises,
    smartGeneration: true,
    fallbackGenerated: true,
    avoidedExercises: recentExerciseNames,
    avoidedWorkouts: recentWorkoutNames,
    metadata: {
      generatedAt: new Date().toISOString(),
      smartGeneration: true,
      fallbackUsed: true,
      recentWorkoutsConsidered: recentWorkoutNames.length,
    },
  };
}

/**
 * TOON Format Utilities for Token Optimization
 * Converts workout data to TOON format for 30-60% additional token reduction
 */

/**
 * Convert flattened workout request to TOON format
 * This reduces token usage by 30-60% compared to JSON
 */
function convertToTOONFormat(flattenedRequest) {
  try {
    // Check if TOON is available (async import completed)
    if (!TOON?.stringify) {
      console.warn("⚠️ TOON not loaded yet, using JSON fallback");
      return JSON.stringify(flattenedRequest);
    }

    // Convert the flattened request to TOON tabular format
    const toonData = {
      headers: [
        "userId",
        "duration",
        "recentExercises",
        "recentWorkouts",
        "excludeWarmup",
      ],
      rows: [
        [
          flattenedRequest.userId || "",
          flattenedRequest.duration || 45,
          flattenedRequest.recentExerciseNames?.join("|") || "",
          flattenedRequest.recentWorkoutNames?.join("|") || "",
          flattenedRequest.excludeWarmup || true,
        ],
      ],
    };

    return TOON.stringify(toonData);
  } catch (error) {
    console.warn("⚠️ TOON conversion failed, using fallback JSON:", error);
    return JSON.stringify(flattenedRequest);
  }
}

/**
 * Convert workout exercises to TOON format for AI prompts
 * Highly efficient for uniform exercise data structures
 */
function exercisesToTOON(exercises) {
  try {
    if (!exercises || exercises.length === 0) return "";

    // Check if TOON is available (async import completed)
    if (!TOON?.stringify) {
      console.warn("⚠️ TOON not loaded yet, using text fallback");
      return exercises
        .map((ex) => `${ex.name}: ${ex.targetMuscles?.join(",") || ""}`)
        .join("\n");
    }

    const toonData = {
      headers: ["name", "targetMuscles", "equipment"],
      rows: exercises.map((ex) => [
        ex.name || "",
        ex.targetMuscles?.join(",") || ex.primaryMuscles?.join(",") || "",
        ex.equipment?.join(",") || "Bodyweight",
      ]),
    };

    return TOON.stringify(toonData);
  } catch (error) {
    console.warn("⚠️ Exercise TOON conversion failed:", error);
    return exercises
      .map((ex) => `${ex.name}: ${ex.targetMuscles?.join(",") || ""}`)
      .join("\n");
  }
}

/**
 * Enhanced prompt builder with TOON format optimization
 * Uses TOON for all tabular data to maximize token efficiency
 */
function buildTOONOptimizedPrompt(params) {
  const {
    duration = 45,
    recentExerciseNames = [],
    recentWorkoutNames = [],
    excludeWarmup = true,
    mcpContext = null,
  } = params;

  // Convert recent exercises/workouts to TOON format
  const recentExercisesTOON =
    recentExerciseNames.length > 0 && TOON?.stringify
      ? TOON.stringify({
          headers: ["exerciseName"],
          rows: recentExerciseNames.map((name) => [name]),
        })
      : recentExerciseNames.length > 0
      ? recentExerciseNames.join(", ")
      : "";

  const recentWorkoutsTOON =
    recentWorkoutNames.length > 0 && TOON?.stringify
      ? TOON.stringify({
          headers: ["workoutName"],
          rows: recentWorkoutNames.map((name) => [name]),
        })
      : recentWorkoutNames.length > 0
      ? recentWorkoutNames.join(", ")
      : "";

  // Convert recommended exercises to TOON format if available
  const exercisesTOON = mcpContext?.exerciseRecommendations
    ? exercisesToTOON(mcpContext.exerciseRecommendations.slice(0, 8))
    : "";

  const prompt = `Create ${duration}min bodyweight workout.${
    recentExerciseNames.length > 0
      ? ` Avoid: ${recentExerciseNames.slice(0, 8).join(", ")}`
      : ""
  }

Include ${
    duration <= 30 ? "3-4" : duration <= 45 ? "4-6" : "6-8"
  } main exercises only. NO warmup section.

Return ONLY this exact JSON structure with NO extra fields:
{
  "workout_plan": {
    "name": "Bodyweight Circuit",
    "duration": ${duration},
    "sections": [
      {"name": "Main", "exercises": [
        {"name": "Push-ups", "sets": 3, "reps": "12", "rest": 60},
        {"name": "Squats", "sets": 3, "reps": "15", "rest": 60},
        {"name": "Plank", "sets": 3, "reps": "30s", "rest": 60}
      ]}
    ]
  }
}

CRITICAL: Each exercise must have ONLY these 4 fields:
- name: string (exercise name only)
- sets: number 
- reps: string or number
- rest: number (seconds)

Do NOT include: id, category, equipment, targetRegion, primaryMuscles, secondaryMuscles, difficulty, movementType, movementPattern, gripType, rangeOfMotion, tempo, muscleGroup, muscleInfo, createdAt, updatedAt, weight, restTime, notes, supersetId, supersetIndex, supersetLabel, isSupersetPrimary, isCurrentExercise, exercise object, or any other fields.
Do NOT include warmup section or warmup exercises.`;

  return prompt;
}

module.exports = router;
