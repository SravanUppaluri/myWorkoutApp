# Gemini API Setup for Workout App

## 🔑 Getting Your Gemini API Key

1. **Go to Google AI Studio**: https://makersuite.google.com/app/apikey
2. **Sign in** with your Google account
3. **Create a new API key**
4. **Copy the API key** (it starts with `AIza...`)

## 🛠️ Setup Instructions

### 1. Environment Configuration

```bash
# Navigate to functions directory
cd firebase/functions

# Copy environment template
cp .env.example .env

# Edit .env file and add your Gemini API key
GEMINI_API_KEY=AIzaSyA...your-actual-api-key-here
```

### 2. Firebase Configuration (Production)

```bash
# Set the API key in Firebase Functions config
firebase functions:config:set gemini.key="AIzaSyA...your-actual-api-key-here"

# Verify the configuration
firebase functions:config:get
```

### 3. Install Dependencies

```bash
# Install Node.js dependencies
npm install

# Test the setup
npm run serve
```

## 🧪 Testing

### Local Testing

```bash
# Start Firebase emulators
firebase emulators:start --only functions

# Test the health check endpoint
curl http://localhost:5001/workout-app/us-central1/healthCheck
```

### Function Testing

```javascript
// Test the AI search function
const testData = {
  exerciseName: "Bulgarian split squat",
};

// This will be called from Flutter app
searchExerciseWithAI(testData, {auth: {uid: "test-user"}});
```

## 🔒 Security Notes

- **Never commit** your `.env` file to version control
- **Use Firebase config** for production deployment
- **API key** is secured on the server-side only
- **Rate limiting** is built-in (10 searches per user per day)

## 💰 Cost Considerations

### Gemini Pro Pricing (as of 2024)

- **Free tier**: 60 requests per minute
- **Paid usage**: $0.00025 per 1K characters (input)
- **Output**: $0.0005 per 1K characters (output)

### Estimated Costs

- **Per exercise search**: ~$0.001 - $0.003
- **1000 searches**: ~$1 - $3
- **Much cheaper** than OpenAI GPT-3.5/4

## 🚀 Deployment

```bash
# Deploy to Firebase
firebase deploy --only functions

# Deploy specific function
firebase deploy --only functions:searchExerciseWithAI
```

## 🐛 Troubleshooting

### Common Issues

1. **"Gemini API key is not configured"**

   - Check your `.env` file or Firebase config
   - Ensure the key starts with `AIza`

2. **"Content was blocked by safety filters"**

   - Try rephrasing your exercise search
   - Some terms might trigger safety filters

3. **Rate limit errors**
   - Free tier has 60 requests/minute limit
   - Consider upgrading to paid tier

### Debug Commands

```bash
# Check Firebase config
firebase functions:config:get

# View function logs
firebase functions:log

# Test locally with detailed logs
DEBUG=* npm run serve
```

## 📊 Monitoring

- **Firebase Console**: https://console.firebase.google.com
- **Google Cloud Console**: https://console.cloud.google.com
- **AI Studio Usage**: https://makersuite.google.com/app/apikey

## 🔄 Switching Models

To use different Gemini models, update the client:

```javascript
// In gemini-client.js, change the model
const response = await fetch(
  `${this.baseUrl}/models/gemini-1.5-pro:generateContent?key=${this.apiKey}`
  // ... rest of the config
);
```

Available models:

- `gemini-pro` (recommended)
- `gemini-1.5-pro` (more capable, higher cost)
- `gemini-pro-vision` (for image analysis)
