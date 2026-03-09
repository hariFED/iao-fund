FROM node:22-slim

# Install git and curl for OpenClaw
RUN apt-get update && apt-get install -y git curl && rm -rf /var/lib/apt/lists/*

# Install OpenClaw globally
RUN npm install -g openclaw

# Create workspace directory
WORKDIR /root/.openclaw/workspace

# Copy all memory files
COPY . /root/.openclaw/workspace/

# Set environment variables (these will be overridden by Railway)
ENV IAO_API_BASE=https://iao-fund.vercel.app
ENV PLATFORM_WALLET=8i3Mept58tXY85UeP1AeH3yS6DqD9GK4o8NsMapHG7w4
ENV IAO_PROGRAM_ID=DKhkk9pdyEE5XAvBjpjaB642RkpxJXqRqa7qTT6PmAuw
ENV SOLANA_RPC_URL=https://api.devnet.solana.com

# Expose gateway port
EXPOSE 8080

# Start OpenClaw gateway
CMD ["openclaw", "gateway", "start"]
