const { Client, OAuth1 } = require('@xdevplatform/xdk');

// Create OAuth 1.0a credentials
const oauth1 = new OAuth1({
  apiKey: process.env.X_API_KEY,
  apiSecret: process.env.X_API_SECRET,
  accessToken: process.env.X_ACCESS_TOKEN,
  accessTokenSecret: process.env.X_ACCESS_TOKEN_SECRET,
});

// Load credentials with OAuth 1.0a
const client = new Client({
  oauth1,
});

async function tweet(text) {
  try {
    // Replace literal \n with actual newlines
    const formattedText = text.replace(/\\n/g, '\n');
    const response = await client.posts.create({ text: formattedText });
    console.log('Tweet posted:', response.data.id);
    return response;
  } catch (error) {
    console.error('Error posting tweet:', error.message);
    if (error.data) {
      console.error('Details:', JSON.stringify(error.data, null, 2));
    }
    throw error;
  }
}

// If called directly with args
if (require.main === module) {
  const text = process.argv[2] || 'Testing IAO.FUND Twitter integration 🤖';
  tweet(text);
}

module.exports = { tweet };
