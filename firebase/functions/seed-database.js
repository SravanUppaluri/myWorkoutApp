/**
 * Firestore Database Seeder
 * Seeds exercise data and safety guidelines into Firebase Firestore
 */

const admin = require("firebase-admin");

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

// Exercise data from local development
const exerciseData = [
  {
    id: "push-up",
    name: "Push-up",
    category: "strength",
    targetMuscles: ["chest", "shoulders", "triceps", "core"],
    equipment: ["bodyweight"],
    difficulty: "beginner",
    description:
      "Classic upper body pushing exercise that builds chest, shoulder, and arm strength.",
    instructions:
      "Start in plank position, lower chest to floor, push back up. Keep body straight throughout.",
    safetyTips:
      "Keep core engaged, avoid sagging hips, start on knees if needed",
    injuryRisks: ["wrist strain", "lower back pain", "shoulder impingement"],
    variations: [
      "knee push-ups",
      "diamond push-ups",
      "incline push-ups",
      "decline push-ups",
    ],
    caloriesBurnedPerMinute: 7,
  },
  {
    id: "squat",
    name: "Bodyweight Squat",
    category: "strength",
    targetMuscles: ["quadriceps", "glutes", "hamstrings", "calves"],
    equipment: ["bodyweight"],
    difficulty: "beginner",
    description:
      "Fundamental lower body exercise that strengthens legs and glutes.",
    instructions:
      "Feet shoulder-width apart, lower hips back and down, keep knees behind toes, return to standing.",
    safetyTips: "Keep chest up, weight on heels, knees track over toes",
    injuryRisks: ["knee pain", "lower back strain", "ankle strain"],
    variations: [
      "jump squats",
      "pistol squats",
      "goblet squats",
      "sumo squats",
    ],
    caloriesBurnedPerMinute: 8,
  },
  {
    id: "plank",
    name: "Plank",
    category: "core",
    targetMuscles: ["core", "shoulders", "back", "glutes"],
    equipment: ["bodyweight"],
    difficulty: "beginner",
    description: "Isometric core exercise that builds stability and endurance.",
    instructions:
      "Hold body straight from head to heels, support on forearms and toes.",
    safetyTips: "Keep hips level, breathe normally, avoid holding breath",
    injuryRisks: ["lower back pain", "shoulder strain", "neck tension"],
    variations: [
      "side plank",
      "plank with leg lift",
      "plank jacks",
      "reverse plank",
    ],
    caloriesBurnedPerMinute: 5,
  },
  {
    id: "jumping-jacks",
    name: "Jumping Jacks",
    category: "cardio",
    targetMuscles: ["full body", "cardiovascular system"],
    equipment: ["bodyweight"],
    difficulty: "beginner",
    description:
      "Full body cardio exercise that increases heart rate and coordination.",
    instructions:
      "Jump feet wide while raising arms overhead, jump back to starting position.",
    safetyTips: "Land softly on balls of feet, keep knees slightly bent",
    injuryRisks: ["knee impact", "ankle strain", "shoulder tension"],
    variations: ["step touch", "half jacks", "cross jacks", "star jumps"],
    caloriesBurnedPerMinute: 12,
  },
  {
    id: "burpees",
    name: "Burpees",
    category: "cardio",
    targetMuscles: ["full body", "cardiovascular system", "core"],
    equipment: ["bodyweight"],
    difficulty: "intermediate",
    description:
      "High intensity full body exercise combining squat, plank, and jump.",
    instructions:
      "Squat down, jump back to plank, do push-up, jump feet to hands, jump up with arms overhead.",
    safetyTips:
      "Step back instead of jumping if needed, focus on form over speed",
    injuryRisks: [
      "wrist strain",
      "knee impact",
      "lower back pain",
      "shoulder strain",
    ],
    variations: ["half burpees", "burpee with push-up", "burpee tuck jump"],
    caloriesBurnedPerMinute: 15,
  },
  {
    id: "mountain-climbers",
    name: "Mountain Climbers",
    category: "cardio",
    targetMuscles: ["core", "shoulders", "legs", "cardiovascular system"],
    equipment: ["bodyweight"],
    difficulty: "intermediate",
    description:
      "Dynamic cardio exercise that combines core work with cardiovascular training.",
    instructions:
      "Start in plank position, alternate bringing knees to chest in running motion.",
    safetyTips:
      "Keep hips level, maintain plank position, control the movement",
    injuryRisks: ["wrist strain", "lower back pain", "hip flexor strain"],
    variations: [
      "slow mountain climbers",
      "cross-body mountain climbers",
      "mountain climber push-ups",
    ],
    caloriesBurnedPerMinute: 10,
  },
  {
    id: "lunges",
    name: "Forward Lunges",
    category: "strength",
    targetMuscles: ["quadriceps", "glutes", "hamstrings", "calves"],
    equipment: ["bodyweight"],
    difficulty: "beginner",
    description:
      "Unilateral leg exercise that builds single-leg strength and balance.",
    instructions:
      "Step forward into lunge position, lower back knee toward ground, push back to standing.",
    safetyTips:
      "Keep front knee behind toes, maintain upright torso, control the descent",
    injuryRisks: ["knee strain", "hip flexor strain", "ankle instability"],
    variations: [
      "reverse lunges",
      "walking lunges",
      "lateral lunges",
      "jumping lunges",
    ],
    caloriesBurnedPerMinute: 6,
  },
  {
    id: "high-knees",
    name: "High Knees",
    category: "cardio",
    targetMuscles: [
      "hip flexors",
      "quadriceps",
      "calves",
      "cardiovascular system",
    ],
    equipment: ["bodyweight"],
    difficulty: "beginner",
    description:
      "Dynamic cardio exercise that improves running form and cardiovascular fitness.",
    instructions: "Run in place bringing knees up to hip level with each step.",
    safetyTips:
      "Land on balls of feet, maintain good posture, swing arms naturally",
    injuryRisks: ["knee impact", "hip flexor strain", "calf strain"],
    variations: ["marching in place", "high knee skips", "butt kickers"],
    caloriesBurnedPerMinute: 11,
  },
  {
    id: "tricep-dips",
    name: "Tricep Dips",
    category: "strength",
    targetMuscles: ["triceps", "shoulders", "chest"],
    equipment: ["chair", "bench"],
    difficulty: "intermediate",
    description: "Upper body exercise targeting the triceps using body weight.",
    instructions:
      "Hands on chair edge, legs extended, lower body by bending elbows, push back up.",
    safetyTips:
      "Keep elbows close to body, avoid going too low, use stable surface",
    injuryRisks: ["shoulder strain", "elbow pain", "wrist discomfort"],
    variations: ["bent knee dips", "single leg dips", "feet elevated dips"],
    caloriesBurnedPerMinute: 5,
  },
  {
    id: "wall-sit",
    name: "Wall Sit",
    category: "strength",
    targetMuscles: ["quadriceps", "glutes", "hamstrings", "calves"],
    equipment: ["wall"],
    difficulty: "beginner",
    description: "Isometric lower body exercise that builds leg endurance.",
    instructions:
      "Lean back against wall, slide down to squat position, hold with thighs parallel to floor.",
    safetyTips:
      "Keep knees at 90 degrees, distribute weight evenly, breathe normally",
    injuryRisks: ["knee strain", "lower back pressure", "muscle fatigue"],
    variations: ["single leg wall sit", "wall sit with calf raises"],
    caloriesBurnedPerMinute: 4,
  },
  {
    id: "deadlift",
    name: "Romanian Deadlift",
    category: "strength",
    targetMuscles: ["hamstrings", "glutes", "lower back", "traps"],
    equipment: ["dumbbells", "barbell"],
    difficulty: "intermediate",
    description: "Hip hinge movement that strengthens the posterior chain.",
    instructions:
      "Hinge at hips, lower weight while keeping back straight, drive hips forward to return.",
    safetyTips:
      "Keep weight close to body, maintain neutral spine, engage core",
    injuryRisks: ["lower back injury", "hamstring strain", "knee stress"],
    variations: ["single leg deadlift", "sumo deadlift", "stiff leg deadlift"],
    caloriesBurnedPerMinute: 6,
  },
  {
    id: "pull-up",
    name: "Pull-up",
    category: "strength",
    targetMuscles: ["lats", "biceps", "rhomboids", "rear delts"],
    equipment: ["pull-up bar"],
    difficulty: "advanced",
    description:
      "Vertical pulling exercise that builds upper body and back strength.",
    instructions:
      "Hang from bar with overhand grip, pull body up until chin clears bar, lower with control.",
    safetyTips: "Use full range of motion, avoid swinging, progress gradually",
    injuryRisks: ["shoulder impingement", "elbow strain", "wrist pain"],
    variations: [
      "assisted pull-ups",
      "chin-ups",
      "wide grip pull-ups",
      "negative pull-ups",
    ],
    caloriesBurnedPerMinute: 8,
  },
];

// Safety guidelines data
const safetyGuidelines = {
  general: {
    guidelines: [
      "Always warm up before exercising and cool down afterward",
      "Listen to your body and stop if you feel pain",
      "Start with lighter intensity and progress gradually",
      "Maintain proper form throughout all exercises",
      "Stay hydrated during workouts",
      "Allow adequate rest between training sessions",
      "Consult a healthcare provider before starting any new exercise program",
    ],
  },
  chest: {
    guidelines: [
      "Keep shoulders back and down during pushing movements",
      "Avoid locking out elbows completely",
      "Control both the lifting and lowering phases",
      "Warm up shoulders thoroughly before chest exercises",
    ],
  },
  legs: {
    guidelines: [
      "Keep knees aligned with toes during squatting movements",
      "Distribute weight evenly across both feet",
      "Avoid letting knees cave inward",
      "Engage core to protect lower back during leg exercises",
    ],
  },
  core: {
    guidelines: [
      "Breathe normally during core exercises, avoid holding breath",
      "Focus on quality over quantity of repetitions",
      "Avoid pulling on neck during crunching movements",
      "Progress gradually to avoid overuse injuries",
    ],
  },
  cardio: {
    guidelines: [
      "Start with shorter durations and build endurance gradually",
      "Land softly during jumping movements to protect joints",
      "Maintain good posture throughout cardio exercises",
      "Monitor heart rate and take breaks as needed",
    ],
  },
};

/**
 * Seed exercises into Firestore
 */
async function seedExercises() {
  console.log("🌱 Seeding exercises into Firestore...");

  try {
    const batch = db.batch();

    exerciseData.forEach((exercise) => {
      const docRef = db.collection("exercises").doc(exercise.id);
      batch.set(docRef, exercise);
    });

    await batch.commit();
    console.log(`✅ Successfully seeded ${exerciseData.length} exercises`);
  } catch (error) {
    console.error("❌ Error seeding exercises:", error);
    throw error;
  }
}

/**
 * Seed safety guidelines into Firestore
 */
async function seedSafetyGuidelines() {
  console.log("🛡️ Seeding safety guidelines into Firestore...");

  try {
    const batch = db.batch();

    Object.entries(safetyGuidelines).forEach(([category, data]) => {
      const docRef = db.collection("safety_guidelines").doc(category);
      batch.set(docRef, data);
    });

    await batch.commit();
    console.log(
      `✅ Successfully seeded ${
        Object.keys(safetyGuidelines).length
      } safety guideline categories`
    );
  } catch (error) {
    console.error("❌ Error seeding safety guidelines:", error);
    throw error;
  }
}

/**
 * Main seeding function
 */
async function seedDatabase() {
  console.log("🚀 Starting Firestore database seeding...");

  try {
    await seedExercises();
    await seedSafetyGuidelines();

    console.log("🎉 Database seeding completed successfully!");
    console.log("📊 Seeded data:");
    console.log(`   - ${exerciseData.length} exercises`);
    console.log(
      `   - ${Object.keys(safetyGuidelines).length} safety guideline categories`
    );

    process.exit(0);
  } catch (error) {
    console.error("💥 Database seeding failed:", error);
    process.exit(1);
  }
}

/**
 * Check if data already exists
 */
async function checkExistingData() {
  try {
    const exercisesSnapshot = await db.collection("exercises").limit(1).get();
    const guidelinesSnapshot = await db
      .collection("safety_guidelines")
      .limit(1)
      .get();

    return {
      exercisesExist: !exercisesSnapshot.empty,
      guidelinesExist: !guidelinesSnapshot.empty,
    };
  } catch (error) {
    console.error("❌ Error checking existing data:", error);
    return {exercisesExist: false, guidelinesExist: false};
  }
}

/**
 * Force reseed (overwrite existing data)
 */
async function forceReseed() {
  console.log("🔄 Force reseeding - this will overwrite existing data...");
  await seedDatabase();
}

// Main execution
if (require.main === module) {
  const args = process.argv.slice(2);

  if (args.includes("--force")) {
    forceReseed();
  } else {
    checkExistingData().then(({exercisesExist, guidelinesExist}) => {
      if (exercisesExist || guidelinesExist) {
        console.log("⚠️ Data already exists in Firestore:");
        console.log(
          `   - Exercises: ${exercisesExist ? "Found" : "Not found"}`
        );
        console.log(
          `   - Guidelines: ${guidelinesExist ? "Found" : "Not found"}`
        );
        console.log("");
        console.log(
          'Use "node seed-database.js --force" to overwrite existing data'
        );
        process.exit(0);
      } else {
        seedDatabase();
      }
    });
  }
}

module.exports = {
  seedDatabase,
  seedExercises,
  seedSafetyGuidelines,
  exerciseData,
  safetyGuidelines,
};
