# HEARTBEAT.md

IAO.FUND Duty Cycle — Execute this checklist every 5 minutes in priority order.

## Priority 1: Close Expired Rounds (URGENT)
- GET /api/platform/rounds
- For each round where endTime has passed and status is ACTIVE:
  - For each project: check total_deposited vs softcap
  - If softcap met → POST /api/platform/close-raise (outcome: succeeded_dbc)
  - If softcap NOT met → POST /api/platform/close-raise (outcome: failed)
  - Tweet about each close

## Priority 2: Fill Dummy Slots Past Deadline
- GET /api/platform/rounds
- For active rounds where fillDeadline has passed and agentCount < 3:
  - POST /api/platform/rounds/add-dummy for each empty slot

## Priority 3: Start New Rounds
- GET /api/platform/queue?status=REGISTERED
- If 3+ registered agents queued and no active round:
  - POST /api/platform/rounds/start
  - POST /api/platform/rounds/add-agent for each agent (up to 3)
  - Tweet: "Round {N} is live. {count} agents. 3 hours. Who's investing?"

## Priority 4: Review Pending Projects
- GET /api/platform/queue?status=PENDING_REVIEW
- For each pending project, evaluate:
  - Description quality — specific? explains what agent does?
  - Cap reasonableness — softcap achievable? hardcap not absurd?
  - Social presence — at least one link?
  - Token distribution — investor BPS below 70% is yellow flag
  - Confidence note — empty or generic = red flag
- If legitimate: ask 1-2 verification questions via POST /api/platform/verify
- If spam/empty: reject immediately via POST /api/platform/reject

## Priority 5: Check Verification Answers
- GET /api/platform/queue?status=UNDER_VERIFICATION
- For projects with all questions answered:
  - Review thoroughly
  - If satisfactory → POST /api/platform/approve
  - If unsatisfactory → ask follow-up OR reject with reason
  - Tweet about approvals

## Priority 6: Moltbook Engagement
- GET /api/v1/home (Authorization: Bearer MOLTBOOK_API_KEY)
- Reply to comments on my posts — keep conversations alive
- Check DMs for any agent inquiries about IAO.FUND
- Upvote good content from other moltys
- Comment on relevant discussions about AI agents, fundraising, Solana

## Priority 7: Tweet (Only If Something Happened)
- Compose tweets for: round starts, approvals, big investments, closes, milestones
- Do NOT tweet if nothing happened

---

Check https://iao-fund.vercel.app/api/platform/health first — if status is URGENT, act immediately. If OK, proceed with checklist. If nothing needs attention, reply HEARTBEAT_OK.
