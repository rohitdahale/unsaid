# UNSAID — Product Requirements Document (MVP v1.1)

**Tagline:** "What people don't say at work."
**Status:** Draft v1.1 — updated with long-term product direction (see Changelog)
**Scope:** MVP / early-stage startup build, not enterprise scale

> **Changelog v1.0 → v1.1:** Added long-term evolution vision (Phase 1–5), shifted identity model to anonymous-first/pseudonym-primary, made **company anonymity** a default product decision (category-based workplace context replaces named-company-first UX), generalized the data model around a first-class **Content/Post** concept with Story/Experience as a subtype, added architecture principle for future Communities/Rooms/Chat/Follow modules without building them now, updated navigation and success-metric guidance. Section numbers from v1.0 are preserved where content is unchanged; amended sections are marked **(updated)**.

---

## 1. Executive Summary

UNSAID is an anonymous platform for honest conversations about professional life, starting with a narrow, sharp wedge: **anonymous workplace stories**. It combines the confessional honesty of Reddit with a structured-data layer (why people leave, red/green flags) and modern social feed pacing. The MVP is intentionally small — one strong behavior, done well — but the underlying architecture is built as a generic content platform so it can evolve into topic communities, rooms, and eventually anonymous conversation, **only as user behavior earns each step**.

Branding, company references, and product copy are kept decoupled from data models so both a rebrand and the shift from "company reviews" to "professional life stories" remain config/data changes, not rebuilds.

---

## 2. Problem Statement

Every existing source of "what a company is like" is produced or curated by a party with an incentive to look good. Prospective and current employees have almost no access to unfiltered peer experience — why people actually quit, what raises red flags, whether "great culture" claims hold up — without exposing their own identity to their employer, manager, or colleagues in the process. UNSAID closes that gap: honest, anonymous, structured testimony about professional life, without the exposure risk of a real-name platform.

---

## 3. Vision **(updated)**

**Short-term:** Build the place people check before accepting an offer or after a bad week at work — a small number of excellent features that make a user think *"I wish I had seen this before joining."*

**Long-term:** UNSAID is not intended to remain a workplace-review website. The vision is an anonymous social platform where people discuss the realities of professional life without exposing their real-world identity — stories evolving into topic conversations, conversations into communities, communities into deeper real-time interaction.

```
PHASE 1              PHASE 2                  PHASE 3                PHASE 4
Anonymous      →     Social conversations  →  Rooms / real-time  →   Chat & deeper
workplace             + topic communities      community discussion   community interaction
stories
```

**Guiding principle:** *Start as a story platform. Evolve into a social platform.* Phases 2–4 are **not** built in MVP — see §33 for the full phased roadmap. The MVP's job is architectural: don't make that evolution unnecessarily hard, without over-engineering for it now.

---

## 4. Target Users

*(unchanged from v1.0)*

| Segment | Need |
|---|---|
| A. Students / fresh graduates | Research companies/workplaces before applying/joining |
| B. Job seekers | Validate an offer or upcoming interview |
| C. Current employees | Vent/share anonymously without career risk |
| D. Former employees | Explain, process, or warn others why they left |
| E. Working professionals | Diligence before a lateral/senior move |

**Geography:** India-first, no hard-coded India logic in data models.

---

## 5. User Personas

*(unchanged — Ananya, Rohan, Priya, Vikram; see v1.0 detail)*

---

## 6. User Stories **(updated)**

**MUST HAVE — MVP**
- As a visitor, I can browse trending stories and discover workplace experiences by category (industry, company size/type, role) without creating an account.
- As a user, I can optionally search or identify a specific company if I choose to when sharing a story, but the platform does not require named-company browsing as the primary discovery path.
- As a user, I can create an account under a private, anonymous pseudonym.
- As a user, I can publish an anonymous, structured story about my workplace experience.
- As a user, I can tag my story with structured reasons and red/green flags.
- As a user, I can react to and comment on a story (one reply level).
- As a user, I can report a story or comment.
- As a user, I can bookmark stories.
- As a user, I receive basic notifications about replies to my content.
- As an admin, I can view and act on reported content, and suspend/ban abusive users.

**SHOULD HAVE — Later (Phase 2)**
- As a user, I can follow topics/communities.
- As a user, I can post questions, polls, or advice, not just structured experience stories.
- As a user, I can get a badge for verified employment without revealing my identity.

**WON'T HAVE — Not now (Phase 3/4)**
- As a user, I can join a live discussion room.
- As a user, I can message another user privately.
- As an employer, I can respond to reviews from a company dashboard.

---

## 7. Product Principles **(updated)**

1. **Story-first, not database-first.** Ratings support stories; stories are the product.
2. **Small and polished beats large and mediocre.** Every feature must pass: *does this help discover, understand, or share professional-life experience?*
3. **Anonymous is not unmoderated.** Public anonymity, internal accountability.
4. **Signal, not accusation.** Aggregate language ("reported by contributors"), never asserted fact about named individuals or companies.
5. **Anonymous-first identity.** Real identity → private account → public pseudonym. The pseudonym, not the real name, is the platform's atomic public identity.
6. **Company anonymity by default.** The product is not dependent on displaying real company names; workplace context (industry, size, type, location region, role) is the default public framing. Named companies are an optional layer, not the foundation.
7. **Content is generic, not review-shaped.** Internally, everything is a `Post`/`Content` object; "Experience/Story" is one subtype today, not the whole schema.
8. **Earn every future feature.** Communities, rooms, chat, and following are justified by observed user behavior (§32), not built because competitors have them.
9. **Transparent math over black-box AI.** Scores and breakdowns are simple, explainable aggregations for v1; AI, if ever used (Phase 5), summarizes real community content and must never invent experiences.
10. **Rebrandable and evolvable by design.** No hard-coded product name, copy, or "review site" assumptions baked into data models or core logic.

---

## 8. MVP Scope

*(unchanged in spirit — see §33 Phase 1 for the authoritative MVP feature list)*

**In scope now:** onboarding, anonymous-pseudonym identity, home/discover feed, workplace-context-based discovery (categories, optionally named companies), story/experience creation, reasons-for-leaving aggregation, red/green flags, lightweight reactions, single-level comments, reporting, human-driven admin moderation, minimal user profile, bookmarks, minimal notifications.

**Explicitly out of scope for MVP:** topic communities, rooms, chat/DMs, following/social graph, polls/questions/advice post types, AI summaries — all Phase 2–5, see §33.

---

## 9. Feature Requirements

### 9.1 Onboarding — MUST
Welcome → optional interest/category selection → optional account creation. Browsing is available without an account; posting, commenting, reacting, bookmarking require an account.

### 9.2 Home / Discover Feed — MUST **(updated)**
Sections: 🔥 Trending, 🆕 Recent, 💬 Most Discussed, 🚩 Red Flags, 🟢 Good Experiences. Feels like a modern anonymous social feed, not a review database or LinkedIn. Cards lead with the story hook, then anonymized context (role, workplace category, tenure), then engagement counts.

Example card:

```
"POV: You finally quit after 14 months."

Anonymous · Software Engineer
Large IT Services Company · 1–2 years

"The interview experience was amazing.
The actual job was completely different..."

❤️ 284   💬 42   🚩 91
```

Ranking factors unchanged from v1.0 (recency + engagement + quality + diversity, no ML).

### 9.3 Workplace Context Discovery — MUST **(replaces "Company Search" as primary path)**
Discovery is organized primarily around **workplace context categories** — industry, company size/type (Startup, Mid-size Product Company, Large IT Services Company, Consulting Firm, Government Organization, etc.), location region, and role — rather than requiring a named-company lookup. A user can still search/filter by a specific named company if one is on file, but this is a secondary, optional path, not the default discovery mental model. See §12 for the anonymity rationale.

### 9.4 Workplace / Category Profile — MUST **(replaces "Company Profile" as the primary aggregation surface)**
Aggregation pages exist at the **category level** (e.g., "Large IT Services Companies — Software Engineering") as the default, with an optional named-company page available only when enough users have voluntarily associated stories with a specific, identifiable company and the minimum-sample threshold (§15) is met. Either page type shows: category score bars (Culture, Management, Work-Life Balance, Compensation, Growth), "Why people leave" breakdown, common red/green flags, latest stories.

### 9.5 Story / Experience Creation — MUST **(updated)**
Multi-step flow: **Workplace context** (industry, company size/type, location region — named company optional/free-text) → Employment status → Role → Duration → Overall rating → Category ratings → Primary reason → Free-text story. Pre-submit reminder against naming individuals and against combining attributes so precisely that a specific company becomes identifiable when the author hasn't chosen to name it (§12).

### 9.6 Anonymous-First Identity — MUST **(updated)**
Identity model: **Real identity → Private account → Public pseudonym.** Public users see only pseudonym/handle, optional generic avatar, contribution count, badges — never real name, email, phone, or other contact info. Internal account linkage is retained solely for abuse prevention, spam prevention, moderation, security, legal compliance, and account recovery.

### 9.7 Reasons for Leaving — MUST
Unchanged: fixed structured multi-select taxonomy, aggregated into the "Why people leave" chart at the category or (optional) company level.

### 9.8 Red Flags / Green Flags — MUST
Unchanged: fixed taxonomy, aggregated and surfaced on the workplace/category or optional company page.

### 9.9 Reactions — MUST
Unchanged: four fixed types (❤️ Relatable, 👀 Interesting, 🚩 Red flag, 🟢 Good sign), one per user per post.

### 9.10 Comments — MUST **(updated framing)**
Comments remain single-level for MVP (`Post → Comment → Reply`, one reply level max), but are modeled on the backend as a **Discussion** concept attached to any `Post`, not hard-coded to "reviews," so it can later support richer nested threads (Phase 2/3) without a schema rewrite.

### 9.11 Reporting — MUST
Unchanged.

### 9.12 Moderation (Admin) — MUST
Unchanged. Every future social surface (Phase 2+) must pass through this same moderation module rather than growing its own — see §31.

### 9.13 User Profile (minimal) — MUST
Unchanged: pseudonymous handle, contribution count, badges. No public employment history exposure in MVP.

### 9.14 Save / Bookmark — MUST
Unchanged. Note: bookmarks are the **only** save/follow mechanism in MVP — no following of users, topics, or communities yet (§28).

### 9.15 Notifications — MUST
Unchanged: four fixed trigger types.

---

## 10. Detailed User Flows **(updated)**

**Flow A — First-time visitor discovers a workplace category**
Splash → Home (no login) → tap Explore/Search → browse by category (e.g., "Large IT Services Companies") or optionally search a named company if listed → Category/Company Profile → scroll aggregated scores → tap a story → Story Detail → prompted to sign up only when attempting to react/comment/save.

**Flow B — Publish a story**
Home → tap Create → login prompt if needed → Step 1 Workplace context (industry/size/type/region, named company optional) → Step 2 Employment status → Step 3 Role → Step 4 Duration → Step 5 Overall rating → Step 6 Category ratings → Step 7 Primary reason → Step 8 Free-text story + reminder banner (no naming individuals; no over-precise identifying detail) → Review → Submit → confirmation.

**Flow C — Report and moderation** — unchanged from v1.0.

**Flow D — Category with no prior stories**
User browses to a category with zero stories → shell page renders with "Be the first to share your experience in this category" CTA — no company-creation step required, since named companies are optional in MVP.

---

## 11. Screen-by-Screen Requirements **(updated)**

1. **Splash**
2. **Welcome**
3. **Login/Signup**
4. **Home** — feed per §9.2
5. **Explore/Search** — category browse + optional named-company search
6. **Search/Category Results**
7. **Workplace/Company Profile** — generic aggregation surface per §9.4 (renders identically whether backed by a category or an optional named company)
8. **Story Detail**
9. **Create Story** — per §9.5
10. **Comments**
11. **Saved**
12. **Notifications**
13. **Minimal Profile**
14. **Settings**
15. **Report Content**
16. **Admin Login**
17. **Admin Dashboard**
18. **Admin Reports**
19. **Admin Content Moderation**

*(Screen count unchanged from v1.0; "Company Profile" is now a shared template rather than an implicitly named-company-only surface.)*

---

## 12. Company Anonymity Direction *(new section)*

For MVP, the product is **not dependent on displaying real company names**. Default public framing uses broader workplace attributes instead:

- Industry
- Company size
- Company type (Startup, Mid-size Product Company, Large IT Services Company, Large Financial Services Company, Consulting Firm, Manufacturing Company, Government Organization, etc.)
- Location region
- Role
- Experience duration
- Work mode
- Salary band (future/optional)

Example: instead of "TCS — Software Engineer," the public story context reads **"Large IT Services Company · Software Engineer · 1–2 years."**

This is an intentional decision to reduce company-specific legal and reputational risk in v1. The product must **not** allow users to indirectly identify a specific company through excessively precise combinations of attributes — the story-creation flow and moderation pre-filter should both guard against this (§19). The backend may privately support named-company entities for moderation/analytics/optional display, but the public MVP experience does not require named-company pages as the primary path.

---

## 13. Information Architecture

```
Root
├─ Public (unauthenticated)
│  ├─ Home
│  ├─ Explore/Search (category-first, named-company optional)
│  ├─ Workplace/Company Profile (read-only)
│  └─ Story Detail (read-only)
├─ Authenticated
│  ├─ Create Story
│  ├─ Comments (write)
│  ├─ Reactions
│  ├─ Saved
│  ├─ Notifications
│  └─ Profile / Settings
└─ Admin (separate auth boundary)
   ├─ Dashboard
   ├─ Reports Queue
   └─ Content Moderation
```

---

## 14. Navigation Structure **(updated)**

MVP bottom navigation remains 5 items: **Home · Search · Create · Saved · Profile.** Create is visually emphasized but not oversized. Do **not** add Communities, Rooms, or Chat to navigation yet — do not reserve permanent navigation slots for features that don't exist. When Phase 2 (topic communities) is validated, navigation can evolve to **Home · Explore · Create · Communities · Profile**; chat, if it ever ships, is introduced via a dedicated entry point based on actual usage, not a pre-reserved slot.

---

## 15. Data Models **(updated — generic Content/Post model)**

The core architectural change: **content is generic, not review-shaped.** A `Post` is the base object; `Experience` is today's only real subtype (structured workplace story), with room for future subtypes (Question, Poll, Discussion, Advice, Confession, Announcement) added later **without a schema rewrite**.

```
User
  id, email, authProvider, createdAt, status(active|suspended|banned), role(user|moderator|admin)

PublicProfile
  userId, displayName/pseudonym, avatar(generic/generated),
  badges[], contributionCount, createdAt

Post  (generic content object — base for all user-generated content)
  id, authorId, type(STORY|EXPERIENCE), title, body,
  context{ }         // structured, type-specific payload — see Experience below
  tags[], reactionsSummary, commentCount,
  status(pending|published|removed), createdAt, updatedAt

Experience  (context payload for type=EXPERIENCE, embedded or referenced from Post)
  postId,
  workplaceContext{ industry, companySize, companyType, locationRegion,
                     companyId(nullable, optional/private) },
  employmentStatus(current|former), role, experienceDuration(band),
  overallRating, managementRating, cultureRating, growthRating,
  compensationRating, workLifeRating,
  reasonTags[], redFlags[], greenFlags[], primaryReason

Company  (optional, may remain private/unlisted)
  id, name, slug, logo, industry, locations[], description,
  overallRating, reviewCount, status(pending|verified|private), createdAt

Comment
  id, postId, authorId, parentCommentId(nullable),
  body, status(published|removed), createdAt

Reaction
  id, userId, postId, type(relatable|interesting|redflag|goodsign), createdAt

Bookmark
  id, userId, targetType(post|company|category), targetId, createdAt

Report
  id, reporterId, targetType(post|comment), targetId,
  reason, description, status(open|resolved), moderatorId, createdAt, resolvedAt

Notification
  id, userId, type, referenceId, read(bool), createdAt

ModerationLog
  id, moderatorId, targetType, targetId, action, reason, createdAt
```

**Deliberately not implemented in MVP, but reserved conceptually for Phase 2+ (do not build now):** `Community`, `CommunityMember`, `Room`, `RoomMember`, `Follow`, `Message`. These are named here only so the `Post`/`Content` model isn't accidentally designed in a way that blocks them later (e.g., a `Post` should be attachable to a future `communityId` without restructuring `Post` itself).

---

## 16. Content Architecture *(new section)*

```
Content (Post)
 ├── Story / Experience        ← MVP, built now
 └── Future content types      ← Question, Poll, Discussion, Advice,
                                  Confession, Announcement (Phase 2+, not built now)
```

Rather than a schema of `Review, Review, Review`, everything is user-generated `Content`, with `Experience` as the first and currently-only subtype. This is what makes the transition from "workplace-story app" to "social platform" a data-model non-event later, rather than a migration project.

---

## 17. API Requirements

REST, versioned under `/api/v1/`. Representative endpoints, updated to the generic content model:

- `GET /discover?industry=&companySize=&companyType=&region=&role=` — category-first discovery
- `GET /companies?query=` — optional named-company search (secondary path)
- `GET /workplace-profile?context=` or `GET /companies/:slug` — aggregated profile (category or optional named company)
- `POST /posts` (type=EXPERIENCE) — create story (auth required)
- `GET /posts/:id` — post/story detail
- `GET /discover/:contextId/posts` — posts for a category or optional company
- `POST /posts/:id/reactions` — react (auth)
- `POST /posts/:id/comments`, `POST /comments/:id/replies` — comments (auth)
- `POST /reports` — file a report (auth)
- `GET/POST /bookmarks` — save/unsave (auth)
- `GET /notifications` — list (auth)
- `POST /admin/reports/:id/action` — moderation action (admin auth)
- `GET /admin/dashboard/metrics` — admin metrics (admin auth)

All list endpoints paginated; write endpoints rate-limited (§27).

---

## 18. Authentication

Unchanged from v1.0: Firebase Authentication (email/password + optional Google OAuth) or JWT-based, admin auth isolated and higher-friction (MFA recommended).

---

## 19. Authorization & Trust & Safety **(updated)**

Roles unchanged (`user`, `moderator`, `admin`). Trust concepts unchanged: **Anonymous**, **Experience Verified** (Phase 2/3), **Community Signal** (aggregate, non-accusatory language only).

**New for this revision:** the pre-submission reminder and the moderation pre-filter must also guard against **indirect company identification** — i.e., a combination of workplace attributes precise enough (e.g., an unusual industry + exact city + very specific role + specific timeframe) to effectively name an unnamed company. This is treated the same class of risk as naming an individual.

---

## 20. Privacy Requirements

Unchanged from v1.0 (disallowed content categories, required legal surfaces, internal-only account data separation) — see original list: no personal attacks, doxxing, private contact info, financial/account data, confidential documents, trade secrets, customer data, or other non-public personal information.

---

## 21. Analytics Events

Unchanged event set, generalized to `post_created`/`post_published`/`post_viewed` instead of `story_*` to match the generic content model, plus `company_context_selected` (whether a story used a named company or category-only context) to help measure how the anonymity default is actually used.

---

## 22. MVP Success Metrics **(updated — see §32 for full strategy)**

Primary: story creation rate, stories read per session. Supporting: registered users, DAU/WAU, category/company discovery usage, engagement rate, saves, report volume, 7-day return rate, comment rate. V1 success is explicitly **not** measured by feature/screen/collection count (§32).

---

## 23. Technical Architecture **(updated — modular monolith)**

- **Frontend:** React + Vite + TypeScript + Tailwind CSS
- **Backend:** Node.js + Express + TypeScript, structured as a **modular monolith** with clear domain boundaries: `Auth`, `Content` (Posts/Experience), `Comments`, `Reactions`, `Bookmarks`, `Notifications`, `Moderation`. Each module owns its own data access and exposes a narrow internal interface, so future modules (`Communities`, `Rooms`, `Follows`, `Messaging`, `Live`, `AI/Insights`) can be added independently later without refactoring existing ones. Do **not** split into microservices for MVP.
- **Database:** MongoDB (Atlas)
- **Auth:** Firebase Authentication (or JWT)
- **Storage:** Cloud object storage for logos/media
- **Deployment:** Frontend on Vercel/Netlify, backend on Render/Railway/AWS, DB on MongoDB Atlas

---

## 24. Database Architecture

MongoDB collections mirror §15: `users`, `publicProfiles`, `posts`, `experiences` (or embedded in `posts.context`), `companies`, `comments`, `reactions`, `bookmarks`, `reports`, `notifications`, `moderationLogs`. Indexes: `posts.type`, `posts.status`, `experiences.workplaceContext.industry/companyType/locationRegion`, `companies.slug` (unique, sparse — since company is optional), `reports.status`, `comments.postId`. Category-level and optional-company-level aggregates computed on read with short-TTL caching, same as v1.0.

---

## 25. Admin Requirements

Unchanged from v1.0.

---

## 26. Error, Empty & Loading States

Unchanged from v1.0, with one addition: a category page with zero stories renders the same shell/CTA pattern as a v1.0 empty company page — "Be the first to share your experience in this category" — since named companies are now optional rather than required for a discoverable page to exist.

---

## 27. Security Requirements

Unchanged from v1.0, plus: pre-filter/moderation logic must specifically check for **combinatorial re-identification risk** (over-precise workplace attribute combinations), not just PII patterns — per §19.

---

## 28. Performance, SEO & Accessibility Requirements **(note)**

Unchanged in substance from v1.0 §30–§32, with one adjustment: SEO structured data (§31 of v1.0) should be applied to **category/workplace-profile pages** as the primary indexable surface, with optional named-company pages indexed only where they exist and meet the sample threshold — since category pages, not company pages, are now the default public discovery surface.

---

## 29. Explicit MVP Non-Goals **(updated)**

Jobs marketplace, recruiter marketplace, employer subscriptions/advertising, salary negotiation tools, resume builder, AI career coach, AI-generated reviews, advanced AI moderation, video stories, private messaging, professional networking, complex employer dashboards, corporate analytics, paid memberships, internationalization/multi-language support, advanced ML recommendation engine, **topic communities, rooms, live discussions, chat (1:1 or group), following/social graph, polls/questions/advice post types** (all reserved for Phase 2+, see §33).

---

## 30. Modular Monolith / Domain Boundaries *(new section — architecture principle for future expansion)*

Current modules (built now): `Auth`, `Content`, `Comments`, `Reactions`, `Bookmarks`, `Notifications`, `Moderation`.

Future modules (added independently, later, only when earned): `Communities`, `Rooms`, `Follows`, `Messaging`, `Live`, `AI/Insights`.

Rule: no future module should require restructuring an existing one to attach to it. Concretely — `Post` should be able to gain an optional `communityId` field later without touching `Experience`'s schema; `Comment`'s single-level structure should be extendable to deeper threading later without a data migration that breaks existing comments; `Moderation` should be the single enforcement point every future social surface (rooms, chat, communities) routes through, rather than each new module building its own reporting/moderation logic.

---

## 31. Every New Social Feature = New Risk Review *(new section, replaces/extends v1.0 §19 legal note)*

Every future social feature — especially chat, rooms, user-to-user interaction, anonymous groups, live discussions — must be evaluated for increased abuse/legal risk **before** launch, and must ship with: reporting, blocking, moderation coverage, rate limits, abuse detection, updated community guidelines, a data retention policy, account enforcement mechanisms, and appropriate legal review. These are not "simple UI additions" — they are treated as new risk surfaces with their own launch checklist.

---

## 32. Product Success Strategy *(new section)*

V1 success is **not** measured by number of features, screens, or database collections. It is measured by:

1. Stories read per session
2. Percentage of users reading multiple stories in a session
3. Story creation rate
4. Comment rate
5. Return rate (especially 7-day return)
6. Number of meaningful discussions (comment depth/engagement, not just count)

**Decision rule:** if users naturally progress from *reading → commenting → sharing → returning*, Phase 2 (communities) becomes justified. If they want deeper discussion → build Communities. If they want live conversation → build Rooms. If they want direct interaction → build Chat. If they want discovery → build Following. If they want insights → build AI summaries (Phase 5, and only as a summarizer of real content, never a generator of synthetic reviews). No future feature is built because a competitor has it — every one must be earned by observed behavior on this list.

---

## 33. Long-Term Roadmap **(fully updated — authoritative phase breakdown)**

### Phase 1 — MVP: Anonymous Workplace Story Platform
**Goal:** Validate whether people want to read and share anonymous workplace/professional-life experiences.
Features: feed, stories/experiences, workplace context (category-first, optional named company), structured ratings, reasons for leaving, red/green flags, reactions, single-level comments, search/discovery, bookmarks, reporting, moderation, basic notifications.

### Phase 2 — Social Layer
**Goal:** Increase daily engagement beyond workplace-story research use cases.
Adds: topic communities (e.g., "Freshers," "Layoffs," "Remote Life," "Office Politics"), follow topics/communities, new post types (Question, Poll, Advice), better discovery/trending, user reputation/badges, richer notifications.

### Phase 3 — Community Layer
**Goal:** Turn UNSAID into a place people visit regularly, not only when researching a workplace.
Adds: Rooms (persistent or temporary topic-based discussion spaces), community moderators, live discussions, room-specific feeds, community events.

### Phase 4 — Conversation Layer
**Goal:** Build deeper social interaction.
Adds (high-risk, requires full risk review per §31 before any of these ship): anonymous 1:1 chat, room/community chat, temporary group conversations, possibly voice/live discussion if validated, advanced community moderation tooling.

### Phase 5 — Intelligence Layer
**Goal:** Surface patterns and insights from real community content.
Adds: AI-generated topic/company summaries, pattern detection, personalized feeds, community recommendations, workplace trend reports, industry insights. **Hard constraint:** AI summarizes community-generated information; it must never invent workplace experiences or generate synthetic reviews.

---

## 34. Development Phases (Build Sequencing for Phase 1/MVP Only)

Unchanged from v1.0 — Phase 0 Foundation, Phase 1 Core Read Path, Phase 2 Core Write Path, Phase 3 Trust & Safety, Phase 4 Polish & Launch Readiness. (Note: this is *build sequencing within the MVP*, distinct from the product Phase 1–5 roadmap in §33 — worth flagging to the team to avoid the two "Phase" numbering schemes being confused in planning docs.)

---

## 35. Acceptance Criteria for Major Features **(updated for amended features)**

**Workplace Context Discovery**
- A user can reach a category aggregation page (e.g., "Large IT Services Companies · Software Engineering") without ever searching a named company.
- Named-company search, where available, is clearly a secondary/optional path in the UI, not the primary CTA.

**Story/Experience Creation**
- The workplace-context step accepts industry/size/type/region as required structured fields and named company as an optional free-text/lookup field.
- The pre-submit reminder and server-side pre-filter both check for over-precise attribute combinations that could indirectly identify an unnamed company, in addition to individual-naming and PII checks.

**Content Model**
- `Post` is created and stored as the base object with `type=EXPERIENCE` for all MVP stories; no MVP code path assumes `Post` can only ever be a review — i.e., adding a new `type` later must not require touching the `Post` schema itself, only adding a new context payload.

**Anonymous-First Identity**
- No API response below admin/moderator-with-cause ever includes a post author's real name, email, or account ID in a public-facing field.

**Navigation**
- Bottom navigation ships with exactly the 5 MVP items; no placeholder/disabled icons for Communities, Rooms, or Chat are present in the MVP build.

*(All other acceptance criteria from v1.0 — Reasons for Leaving, Reactions/Comments, Reporting, Moderation, Notifications — remain unchanged; see v1.0 §36.)*

---

## 36. Legal Note

Community Guidelines, ToS, and Privacy Policy language remains a product-requirements placeholder throughout and must be finalized with counsel before public launch — now additionally covering the company-anonymity mechanism (§12) and the risk-review requirement for any future social feature (§31).

---

*End of PRD v1.1.*
