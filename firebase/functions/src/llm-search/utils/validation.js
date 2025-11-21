/**
 * Validation utilities for AI-generated exercise data
 */

/**
 * Validate exercise data structure and content
 * @param {object} exerciseData - Exercise data to validate
 * @returns {object} Validation result with isValid boolean and errors array
 */
function validateExerciseData(exerciseData) {
  const errors = [];

  // Check if data exists and is an object
  if (!exerciseData || typeof exerciseData !== "object") {
    return {isValid: false, errors: ["Exercise data must be a valid object"]};
  }

  // Required fields validation
  const requiredFields = [
    "name",
    "category",
    "equipment",
    "primaryMuscles",
    "difficulty",
    "muscleGroup",
  ];

  for (const field of requiredFields) {
    if (
      !exerciseData.hasOwnProperty(field) ||
      exerciseData[field] === null ||
      exerciseData[field] === undefined
    ) {
      errors.push(`Missing required field: ${field}`);
    }
  }

  // Field type validations
  if (exerciseData.name && typeof exerciseData.name !== "string") {
    errors.push("Name must be a string");
  }

  if (exerciseData.equipment && !Array.isArray(exerciseData.equipment)) {
    errors.push("Equipment must be an array");
  }

  if (
    exerciseData.primaryMuscles &&
    !Array.isArray(exerciseData.primaryMuscles)
  ) {
    errors.push("Primary muscles must be an array");
  }

  if (
    exerciseData.secondaryMuscles &&
    !Array.isArray(exerciseData.secondaryMuscles)
  ) {
    errors.push("Secondary muscles must be an array");
  }

  if (exerciseData.targetRegion && !Array.isArray(exerciseData.targetRegion)) {
    errors.push("Target region must be an array");
  }

  // Array length validations
  if (exerciseData.equipment && exerciseData.equipment.length === 0) {
    errors.push("Equipment array cannot be empty");
  }

  if (exerciseData.primaryMuscles && exerciseData.primaryMuscles.length === 0) {
    errors.push("Primary muscles array cannot be empty");
  }

  if (exerciseData.targetRegion && exerciseData.targetRegion.length === 0) {
    errors.push("Target region array cannot be empty");
  }

  // Enum validations
  const validCategories = [
    "Strength",
    "Cardio",
    "Flexibility",
    "Sports",
    "Functional",
  ];
  if (
    exerciseData.category &&
    !validCategories.includes(exerciseData.category)
  ) {
    errors.push(`Category must be one of: ${validCategories.join(", ")}`);
  }

  const validDifficulties = ["Beginner", "Intermediate", "Advanced"];
  if (
    exerciseData.difficulty &&
    !validDifficulties.includes(exerciseData.difficulty)
  ) {
    errors.push(`Difficulty must be one of: ${validDifficulties.join(", ")}`);
  }

  const validMovementTypes = ["Compound", "Isolation"];
  if (
    exerciseData.movementType &&
    !validMovementTypes.includes(exerciseData.movementType)
  ) {
    errors.push(
      `Movement type must be one of: ${validMovementTypes.join(", ")}`
    );
  }

  const validMuscleGroups = [
    "Chest",
    "Back",
    "Shoulders",
    "Arms",
    "Legs",
    "Core",
    "Full Body",
  ];
  if (
    exerciseData.muscleGroup &&
    !validMuscleGroups.includes(exerciseData.muscleGroup)
  ) {
    errors.push(`Muscle group must be one of: ${validMuscleGroups.join(", ")}`);
  }

  // String length validations
  if (exerciseData.name && exerciseData.name.length < 2) {
    errors.push("Exercise name must be at least 2 characters long");
  }

  if (exerciseData.name && exerciseData.name.length > 100) {
    errors.push("Exercise name must be less than 100 characters");
  }

  return {
    isValid: errors.length === 0,
    errors: errors,
  };
}

/**
 * Validate an array of exercise data
 * @param {array} exercisesArray - Array of exercise data to validate
 * @returns {object} Validation result
 */
function validateExerciseArray(exercisesArray) {
  if (!Array.isArray(exercisesArray)) {
    return {isValid: false, errors: ["Data must be an array"]};
  }

  if (exercisesArray.length === 0) {
    return {isValid: false, errors: ["Array cannot be empty"]};
  }

  const allErrors = [];
  let validCount = 0;

  exercisesArray.forEach((exercise, index) => {
    const validation = validateExerciseData(exercise);
    if (!validation.isValid) {
      allErrors.push(`Exercise ${index + 1}: ${validation.errors.join(", ")}`);
    } else {
      validCount++;
    }
  });

  return {
    isValid: allErrors.length === 0,
    errors: allErrors,
    validCount: validCount,
    totalCount: exercisesArray.length,
  };
}

/**
 * Sanitize exercise data by cleaning and formatting fields
 * @param {object} exerciseData - Raw exercise data
 * @returns {object} Sanitized exercise data
 */
function sanitizeExerciseData(exerciseData) {
  const sanitized = {...exerciseData};

  // Trim string fields
  if (sanitized.name) sanitized.name = sanitized.name.trim();
  if (sanitized.category) sanitized.category = sanitized.category.trim();
  if (sanitized.difficulty) sanitized.difficulty = sanitized.difficulty.trim();
  if (sanitized.movementType)
    sanitized.movementType = sanitized.movementType.trim();
  if (sanitized.muscleGroup)
    sanitized.muscleGroup = sanitized.muscleGroup.trim();

  // Clean array fields
  if (sanitized.equipment) {
    sanitized.equipment = sanitized.equipment
      .map((item) => item.trim())
      .filter((item) => item.length > 0);
    // Add fallback if equipment becomes empty after filtering
    if (sanitized.equipment.length === 0) {
      sanitized.equipment = ["Bodyweight"];
    }
  } else {
    sanitized.equipment = ["Bodyweight"];
  }

  if (sanitized.primaryMuscles) {
    sanitized.primaryMuscles = sanitized.primaryMuscles
      .map((item) => item.trim())
      .filter((item) => item.length > 0);
    // Add fallback if primaryMuscles becomes empty after filtering
    if (sanitized.primaryMuscles.length === 0) {
      sanitized.primaryMuscles = ["Unknown"];
    }
  } else {
    sanitized.primaryMuscles = ["Unknown"];
  }

  if (sanitized.secondaryMuscles) {
    sanitized.secondaryMuscles = sanitized.secondaryMuscles
      .map((item) => item.trim())
      .filter((item) => item.length > 0);
  }

  if (sanitized.targetRegion) {
    sanitized.targetRegion = sanitized.targetRegion
      .map((item) => item.trim())
      .filter((item) => item.length > 0);
    // Add fallback if targetRegion becomes empty after filtering
    if (sanitized.targetRegion.length === 0) {
      sanitized.targetRegion = ["Full Body"];
    }
  } else {
    sanitized.targetRegion = ["Full Body"];
  }

  // Add default values for optional fields
  if (!sanitized.secondaryMuscles) sanitized.secondaryMuscles = [];
  if (!sanitized.movementType) sanitized.movementType = "Compound";
  if (!sanitized.gripType) sanitized.gripType = "Standard";
  if (!sanitized.rangeOfMotion) sanitized.rangeOfMotion = "Full";
  if (!sanitized.tempo) sanitized.tempo = "Moderate";
  if (!sanitized.movementPattern) sanitized.movementPattern = "Push";

  return sanitized;
}

module.exports = {
  validateExerciseData,
  validateExerciseArray,
  sanitizeExerciseData,
};
