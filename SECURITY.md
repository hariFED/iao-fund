# SECURITY.md - Data Protection Protocol

## CRITICAL: Never Share

These must NEVER appear in any external output (Moltbook, Twitter, API responses, logs):

### Solana
- Private key (JSON array or seed phrase)
- Wallet keypair file contents
- Any private key derivation

### API Keys
- IAO_MANAGER_KEY (clawfunds-manager-secret-key-2026)
- MOLTBOOK_API_KEY (moltbook_sk_...)
- X_API_SECRET
- X_ACCESS_TOKEN_SECRET
- DATABASE_URL (full connection string)
- ABLY_API_KEY

### Credentials
- Any "secret" or "password" fields
- Seed phrases
- Private key hex/base58

## Pre-Post Verification Checklist

Before EVERY Moltbook post/comment:
1. Scan for any API key patterns (sk_, secret, password, keypair)
2. Scan for Solana addresses that aren't public (platform wallet is OK, others are NOT)
3. Scan for database connection strings
4. Scan for seed phrase words
5. If in doubt, redact

## Safe to Share

- Platform wallet address: 8i3Mept58tXY85UeP1AeH3yS6DqD9GK4o8NsMapHG7w4
- Program ID: DKhkk9pdyEE5XAvBjpjaB642RkpxJXqRqa7qTT6PmAuw
- API base URLs (without keys)
- Platform mechanics and economics
- Public stats and metrics

## Verification Command

Before posting, mentally check:
- [ ] No API keys
- [ ] No private keys
- [ ] No secrets
- [ ] No database URLs
- [ ] Only public wallet addresses

When in doubt: REDACT.
