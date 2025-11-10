/**
 * Firebase MCP Service - Production version using Firestore
 * Provides enhanced workout and exercise data from Firebase database
 */

const admin = require("firebase-admin");

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

class FirebaseMCPService {
  constructor() {
    this.exerciseCache = null;
    this.cacheExpiry = null;
    this.initialized = false;
  }

  /**
   * Initialize MCP service
   */
  async initialize() {
    if (this.initialized) return;

    try {
      console.log("🧠 Initializing Firebase MCP Service...");

      // Test Firestore connection
      await db.collection("exercises").limit(1).get();

      this.initialized = true;
      console.log("✅ Firebase MCP Service initialized successfully");
    } catch (error) {
      console.error("❌ Firebase MCP Service initialization failed:", error);
      throw error;
    }
  }

  /**
   * Get workout context for enhanced generation using Firestore
   */
  async getWorkoutContext(params) {
    await this.initialize();

    const {
      userId,
      muscleGroups,
      equipment,
      fitnessLevel,
      goal,
      recentWorkouts,
    } = params;

    console.log("🔍 Firebase MCP: Getting workout context for:", {
      userId,
      muscleGroups,
      fitnessLevel,
    });

    try {
      // ⚡ PERFORMANCE: Run queries in parallel for 3x speed improvement
      const [userWorkoutHistory, exerciseRecommendations, safetyGuidelines] =
        await Promise.all([
          // 1. Get user's recent workout history from Firestore
          this.getUserWorkoutHistory(userId, 4),

          // 2. Query exercises from Firestore (without excludeRecent for now)
          this.queryExerciseDatabase({
            muscleGroups,
            equipment,
            fitnessLevel,
            excludeRecent: [], // Will filter later to avoid dependency
          }),

          // 3. Get safety guidelines from Firestore
          this.getSafetyGuidelines(muscleGroups),
        ]);

      // 4. Filter exercises to exclude recent ones (fast in-memory operation)
      const recentExercises = this.getRecentExercises(userWorkoutHistory);
      const filteredExercises = exerciseRecommendations.filter(
        (ex) => !recentExercises.includes(ex.name?.toLowerCase())
      );

      // 5. Analyze muscle group balance (fast in-memory operation)
      const muscleBalance = this.analyzeMuscleBalance(userWorkoutHistory);

      // 6. Get personalized injury prevention (fast in-memory operation)
      const injuryPrevention =
        this.getPersonalizedInjuryPrevention(fitnessLevel);

      return {
        exerciseRecommendations: filteredExercises,
        workoutHistory: userWorkoutHistory,
        safetyGuidelines,
        injuryPrevention,
        muscleGroupBalance: muscleBalance,
        totalExercisesAvailable: await this.getExerciseCount(),
        enhanced: true,
        source: "firebase_firestore",
      };
    } catch (error) {
      console.error("❌ Firebase MCP Error:", error);
      throw new Error(`Firebase MCP Service failed: ${error.message}`);
    }
  }

  /**
   * Get user's recent workout history from Firestore
   */
  async getUserWorkoutHistory(userId, days = 4) {
    if (!userId) return [];

    const fourDaysAgo = new Date();
    fourDaysAgo.setDate(fourDaysAgo.getDate() - days);

    try {
      const workoutsSnapshot = await db
        .collection("user_workouts")
        .where("userId", "==", userId)
        .where("date", ">=", fourDaysAgo)
        .orderBy("date", "desc")
        .limit(10)
        .get();

      const workouts = [];
      workoutsSnapshot.forEach((doc) => {
        workouts.push({
          id: doc.id,
          ...doc.data(),
        });
      });

      console.log(
        `📊 Found ${workouts.length} recent workouts for user ${userId}`
      );
      return workouts;
    } catch (error) {
      console.warn("⚠️ Could not fetch workout history:", error.message);
      return [];
    }
  }

  /**
   * Query exercise database from Firestore with caching
   */
  async queryExerciseDatabase(params) {
    const {muscleGroups, equipment, fitnessLevel, excludeRecent} = params;

    try {
      // Use cached exercises if available and fresh (10 minutes cache)
      if (this.exerciseCache && this.cacheExpiry > Date.now()) {
        console.log("📋 Using cached exercise data");
        return this.filterExercises(this.exerciseCache, params);
      }

      // Query Firestore for exercises
      console.log("🔄 Fetching exercises from Firestore...");
      const exercisesSnapshot = await db.collection("exercises").get();

      const exercises = [];
      exercisesSnapshot.forEach((doc) => {
        exercises.push({id: doc.id, ...doc.data()});
      });

      // Cache exercises for 10 minutes
      this.exerciseCache = exercises;
      this.cacheExpiry = Date.now() + 10 * 60 * 1000;

      console.log(`💪 Loaded ${exercises.length} exercises from Firestore`);

      // Filter and return relevant exercises
      return this.filterExercises(exercises, params);
    } catch (error) {
      console.error("❌ Exercise database query failed:", error);
      throw new Error(`Exercise query failed: ${error.message}`);
    }
  }

  /**
   * Filter exercises based on criteria
   */
  filterExercises(exercises, params) {
    const {muscleGroups, equipment, fitnessLevel, excludeRecent} = params;

    return exercises
      .filter((exercise) => {
        // Exclude recently done exercises
        if (excludeRecent && excludeRecent.includes(exercise.name)) {
          return false;
        }

        // Match muscle groups
        if (muscleGroups && muscleGroups.length > 0) {
          const hasMatchingMuscles = muscleGroups.some(
            (muscle) =>
              exercise.targetMuscles &&
              exercise.targetMuscles.some(
                (target) =>
                  target.toLowerCase().includes(muscle.toLowerCase()) ||
                  muscle.toLowerCase().includes(target.toLowerCase())
              )
          );
          if (!hasMatchingMuscles) return false;
        }

        // Match equipment
        if (equipment && equipment.length > 0) {
          const hasMatchingEquipment = equipment.some(
            (equip) =>
              exercise.equipment &&
              exercise.equipment.some(
                (exerciseEquip) =>
                  exerciseEquip.toLowerCase().includes(equip.toLowerCase()) ||
                  equip.toLowerCase().includes(exerciseEquip.toLowerCase())
              )
          );
          if (!hasMatchingEquipment) return false;
        }

        // Match fitness level
        if (fitnessLevel && exercise.difficulty) {
          const levelMatch = {
            beginner: ["beginner", "easy"],
            intermediate: ["beginner", "intermediate", "moderate"],
            advanced: ["intermediate", "advanced", "expert"],
          };

          if (
            !levelMatch[fitnessLevel.toLowerCase()]?.includes(
              exercise.difficulty.toLowerCase()
            )
          ) {
            return false;
          }
        }

        return true;
      })
      .slice(0, 12); // Return top 12 matches
  }

  /**
   * Get safety guidelines from Firestore
   */
  async getSafetyGuidelines(muscleGroups) {
    try {
      const safetySnapshot = await db.collection("safety_guidelines").get();

      let guidelines = [];
      safetySnapshot.forEach((doc) => {
        const data = doc.data();

        // Include general guidelines
        if (doc.id === "general") {
          guidelines = [...guidelines, ...(data.guidelines || [])];
        }

        // Include muscle-specific guidelines
        if (muscleGroups) {
          muscleGroups.forEach((muscle) => {
            if (
              doc.id.includes(muscle.toLowerCase()) ||
              muscle.toLowerCase().includes(doc.id)
            ) {
              guidelines = [...guidelines, ...(data.guidelines || [])];
            }
          });
        }
      });

      return guidelines.join("\n");
    } catch (error) {
      console.warn("⚠️ Could not load safety guidelines:", error.message);
      return "Follow general safety principles and proper form.";
    }
  }

  /**
   * Analyze muscle group balance from workout history
   */
  analyzeMuscleBalance(recentWorkouts) {
    const muscleGroupCount = {};

    // Count muscle groups from recent workouts
    recentWorkouts.forEach((workout) => {
      if (workout.muscleGroups) {
        workout.muscleGroups.forEach((muscle) => {
          muscleGroupCount[muscle] = (muscleGroupCount[muscle] || 0) + 1;
        });
      }
    });

    // Determine balance
    const overworked = [];
    const underworked = [];
    const balanced = [];

    Object.entries(muscleGroupCount).forEach(([muscle, count]) => {
      if (count >= 3) overworked.push(muscle);
      else if (count <= 1) underworked.push(muscle);
      else balanced.push(muscle);
    });

    let recommendation;
    if (underworked.length > 0) {
      recommendation = `Focus on ${underworked.join(
        ", "
      )} - underworked in past 4 days`;
    } else if (overworked.length > 0) {
      recommendation = `Consider rest for ${overworked.join(
        ", "
      )} - trained frequently`;
    } else {
      recommendation = "Well balanced training - continue current rotation";
    }

    return {
      overworked,
      underworked,
      balanced,
      recommendation,
      analysis: `Analyzed ${recentWorkouts.length} recent workouts`,
    };
  }

  /**
   * Get personalized injury prevention based on fitness level
   */
  getPersonalizedInjuryPrevention(fitnessLevel) {
    const baseTips = {
      beginner: [
        "Start with bodyweight exercises before adding weights",
        "Focus on form over intensity",
        "Allow 48 hours rest between training same muscle groups",
        "Progress gradually - increase weight by 5-10% weekly",
      ],
      intermediate: [
        "Include proper warm-up and cool-down routines",
        "Listen to your body and rest when needed",
        "Vary your training to prevent overuse injuries",
        "Consider working with a trainer for form checks",
      ],
      advanced: [
        "Periodize your training to prevent overtraining",
        "Include mobility and recovery work",
        "Monitor fatigue and adjust intensity accordingly",
        "Consider deload weeks every 4-6 weeks",
      ],
    };

    return baseTips[fitnessLevel] || baseTips.beginner;
  }

  /**
   * Search exercises in Firestore
   */
  async searchExercises(params) {
    await this.initialize();

    const {query, muscleGroups, equipment, difficulty} = params;

    console.log("🔍 Firebase MCP Exercise Search:", query);

    try {
      // Get all exercises (use cache if available)
      const exercises = this.exerciseCache || [];
      if (!this.exerciseCache) {
        const exercisesSnapshot = await db.collection("exercises").get();
        exercisesSnapshot.forEach((doc) => {
          exercises.push({id: doc.id, ...doc.data()});
        });
      }

      // Search by name and description
      const searchResults = exercises.filter((exercise) => {
        const searchTerm = query.toLowerCase();
        const nameMatch = exercise.name.toLowerCase().includes(searchTerm);
        const descMatch =
          exercise.description?.toLowerCase().includes(searchTerm) || false;
        const muscleMatch =
          exercise.targetMuscles?.some((muscle) =>
            muscle.toLowerCase().includes(searchTerm)
          ) || false;

        return nameMatch || descMatch || muscleMatch;
      });

      return searchResults.slice(0, 8);
    } catch (error) {
      console.error("❌ Exercise search failed:", error);
      return [];
    }
  }

  /**
   * Get exercise variations from Firestore
   */
  async getExerciseVariations(params) {
    await this.initialize();

    const {exerciseName, equipment, difficulty} = params;

    console.log("🔄 Getting exercise variations for:", exerciseName);

    try {
      // Get all exercises
      const exercises = this.exerciseCache || [];
      if (!this.exerciseCache) {
        const exercisesSnapshot = await db.collection("exercises").get();
        exercisesSnapshot.forEach((doc) => {
          exercises.push({id: doc.id, ...doc.data()});
        });
      }

      // Find the base exercise
      const baseExercise = exercises.find(
        (ex) =>
          ex.name.toLowerCase().includes(exerciseName.toLowerCase()) ||
          exerciseName.toLowerCase().includes(ex.name.toLowerCase())
      );

      if (!baseExercise) {
        return [];
      }

      // Find variations based on similar muscle groups
      const variations = exercises.filter((exercise) => {
        if (exercise.name === baseExercise.name) return false;

        // Check if targets similar muscle groups
        const similarMuscles =
          exercise.targetMuscles?.some((muscle) =>
            baseExercise.targetMuscles?.some(
              (baseMuscle) => muscle.toLowerCase() === baseMuscle.toLowerCase()
            )
          ) || false;

        return similarMuscles;
      });

      return variations.slice(0, 6);
    } catch (error) {
      console.error("❌ Exercise variations failed:", error);
      return [];
    }
  }

  /**
   * Get similar exercises from Firestore
   */
  async getSimilarExercises(params) {
    await this.initialize();

    const {exerciseName, targetMuscles, avoidEquipment} = params;

    console.log("🔗 Getting similar exercises for:", exerciseName);

    try {
      // Get all exercises
      const exercises = this.exerciseCache || [];
      if (!this.exerciseCache) {
        const exercisesSnapshot = await db.collection("exercises").get();
        exercisesSnapshot.forEach((doc) => {
          exercises.push({id: doc.id, ...doc.data()});
        });
      }

      const similarExercises = exercises.filter((exercise) => {
        const nameMatch =
          exercise.name.toLowerCase() !== exerciseName.toLowerCase();

        // Check muscle group overlap
        let muscleMatch = true;
        if (targetMuscles && targetMuscles.length > 0) {
          muscleMatch = targetMuscles.some(
            (muscle) =>
              exercise.targetMuscles?.some((target) =>
                target.toLowerCase().includes(muscle.toLowerCase())
              ) || false
          );
        }

        // Avoid certain equipment
        let equipmentOk = true;
        if (avoidEquipment && avoidEquipment.length > 0) {
          equipmentOk = !avoidEquipment.some(
            (avoid) =>
              exercise.equipment?.some((equip) =>
                equip.toLowerCase().includes(avoid.toLowerCase())
              ) || false
          );
        }

        return nameMatch && muscleMatch && equipmentOk;
      });

      return similarExercises.slice(0, 6);
    } catch (error) {
      console.error("❌ Similar exercises failed:", error);
      return [];
    }
  }

  /**
   * Get workout suggestions based on user profile
   */
  async getWorkoutSuggestions(params) {
    await this.initialize();

    const {userProfile, preferences, limit} = params;

    console.log("💡 Getting Firebase workout suggestions for user profile");

    try {
      // Get exercises from cache or Firestore
      const exercises = this.exerciseCache || [];
      if (!this.exerciseCache) {
        const exercisesSnapshot = await db.collection("exercises").get();
        exercisesSnapshot.forEach((doc) => {
          exercises.push({id: doc.id, ...doc.data()});
        });
      }

      // Generate suggestions based on available data
      const suggestions = [
        {
          type: "strength",
          name: "Upper Body Strength Focus",
          description: "Build upper body strength with compound movements",
          recommendedFor: ["muscle_gain", "strength"],
          exercises: exercises
            .filter(
              (ex) =>
                ex.targetMuscles?.some((muscle) =>
                  ["chest", "back", "shoulders", "arms"].some((upper) =>
                    muscle.toLowerCase().includes(upper)
                  )
                ) || false
            )
            .slice(0, 6),
        },
        {
          type: "cardio",
          name: "High Intensity Cardio Circuit",
          description: "Boost cardiovascular fitness with interval training",
          recommendedFor: ["weight_loss", "endurance"],
          exercises: exercises
            .filter(
              (ex) =>
                ex.category === "cardio" ||
                ex.name.toLowerCase().includes("cardio")
            )
            .slice(0, 5),
        },
        {
          type: "functional",
          name: "Functional Movement Training",
          description: "Improve daily movement patterns and stability",
          recommendedFor: ["general_fitness", "flexibility"],
          exercises: exercises
            .filter(
              (ex) =>
                ex.category === "functional" ||
                ["squat", "lunge", "plank", "deadlift"].some((movement) =>
                  ex.name.toLowerCase().includes(movement)
                )
            )
            .slice(0, 6),
        },
      ];

      return suggestions.slice(0, limit || 3);
    } catch (error) {
      console.error("❌ Workout suggestions failed:", error);
      return [];
    }
  }

  /**
   * Helper methods
   */
  getRecentExercises(workouts) {
    const exercises = [];
    workouts.forEach((workout) => {
      if (workout.exercises) {
        exercises.push(...workout.exercises);
      }
    });
    return [...new Set(exercises)]; // Remove duplicates
  }

  async getExerciseCount() {
    try {
      if (this.exerciseCache) {
        return this.exerciseCache.length;
      }

      const snapshot = await db.collection("exercises").get();
      return snapshot.size;
    } catch (error) {
      console.warn("⚠️ Could not get exercise count:", error);
      return 0;
    }
  }

  /**
   * Test connection to Firestore
   */
  async testConnection() {
    try {
      await db.collection("exercises").limit(1).get();
      return true;
    } catch (error) {
      console.error("Firebase MCP connection test failed:", error);
      return false;
    }
  }
}

// Export singleton instance
module.exports = new FirebaseMCPService();
