# 🚀 ViralFlow Automation

**AI-Powered Viral Content Creator Platform** — Generate, Schedule & Monetize Social Media Content

[![Flutter](https://img.shields.io/badge/Flutter-3.19+-02569B?logo=flutter)](https://flutter.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Auth%20%7C%20DB%20%7C%20Edge%20Functions-3ECF8E?logo=supabase)](https://supabase.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## 📱 Overview

ViralFlow Automation is an AI-powered platform that helps content creators, influencers, and businesses create viral social media content, schedule posts at optimal times, track analytics, and monetize through a freemium subscription model.

### ✨ Key Features

| Feature | Description |
|---------|-------------|
| 🤖 **AI Content Generation** | Generate viral captions, hashtags, and images using GPT-4o & DALL-E 3 |
| 📅 **Smart Scheduling** | AI-powered best time suggestions for maximum engagement |
| 📊 **Analytics Dashboard** | Track views, engagement, growth across all platforms |
| 💳 **Subscription System** | Freemium model with Razorpay payments (Free/Pro/Enterprise) |
| 🔗 **Multi-Platform** | Instagram, YouTube, Twitter, LinkedIn, Facebook, TikTok |
| 🌐 **Hinglish Support** | AI generates content in Hinglish, English, and Hindi |
| 🎨 **Image Generation** | Create stunning social media images with DALL-E 3 |
| 📈 **Trend Tracking** | Discover trending topics and viral content ideas |

---

## 💰 Earning Model

| Plan | Price | Credits/Month | Best For |
|------|-------|---------------|----------|
| **Free** | ₹0 | 10 | Getting started |
| **Pro** ⭐ | ₹499/mo or ₹4,999/yr | 200 | Creators & influencers |
| **Enterprise** | ₹1,999/mo or ₹19,999/yr | Unlimited | Teams & agencies |

**Revenue Streams:**
1. **Subscription Revenue** — Monthly/Yearly recurring payments
2. **Credit Top-ups** — Buy additional credits when exhausted
3. **Referral System** — 5 bonus credits per referral (viral growth)

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────┐
│                   Flutter App                        │
│  ┌──────────┐ ┌──────────┐ ┌──────────────────────┐ │
│  │ Riverpod │ │ GoRouter │ │ Material 3 + Charts  │ │
│  └──────────┘ └──────────┘ └──────────────────────┘ │
└─────────────────────┬───────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────┐
│                Supabase Backend                      │
│  ┌──────────┐ ┌──────────┐ ┌──────────────────────┐ │
│  │   Auth   │ │ Database │ │   Edge Functions     │ │
│  │ (OAuth)  │ │(Postgres)│ │ (Deno/TypeScript)    │ │
│  └──────────┘ └──────────┘ └──────────────────────┘ │
│  ┌──────────┐ ┌──────────┐ ┌──────────────────────┐ │
│  │ Storage  │ │   RLS    │ │  Realtime Subs       │ │
│  └──────────┘ └──────────┘ └──────────────────────┘ │
└─────────────────────┬───────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────┐
│              External Services                      │
│  ┌──────────┐ ┌──────────┐ ┌──────────────────────┐│
│  │ OpenAI   │ │ Razorpay │ │ Social Media APIs     ││
│  │GPT-4o/D3│ │ Payments │ │(IG, YT, Twitter, etc) ││
│  └──────────┘ └──────────┘ └──────────────────────┘│
└─────────────────────────────────────────────────────┘
```

---

## 📁 Project Structure

```
ViralFlowAutomation/
├── lib/
│   ├── main.dart                          # App entry point
│   ├── app/
│   │   ├── app_theme.dart                 # Light/Dark theme config
│   │   └── app_router.dart                # GoRouter with auth guards
│   ├── core/
│   │   ├── config/
│   │   │   └── env_config.dart            # API keys & env config
│   │   ├── models/
│   │   │   ├── user_model.dart            # User model (Freezed)
│   │   │   ├── content_model.dart         # Content model with enums
│   │   │   └── subscription_model.dart    # Subscription & plan models
│   │   ├── services/
│   │   │   ├── auth_service.dart          # Supabase auth operations
│   │   │   ├── ai_service.dart            # AI content generation
│   │   │   ├── content_service.dart       # Content CRUD operations
│   │   │   ├── subscription_service.dart  # Razorpay & subscriptions
│   │   │   └── analytics_service.dart     # Analytics data service
│   │   └── providers/
│   │       └── providers.dart             # Riverpod providers
│   └── features/
│       ├── auth/presentation/pages/
│       │   ├── splash_page.dart           # Animated splash screen
│       │   ├── login_page.dart            # Login with Google OAuth
│       │   └── signup_page.dart           # Registration page
│       ├── home/presentation/pages/
│       │   └── home_shell.dart            # Bottom navigation shell
│       ├── dashboard/presentation/pages/
│       │   └── dashboard_page.dart        # Main dashboard with stats
│       ├── content/presentation/pages/
│       │   ├── create_content_page.dart   # AI content creation form
│       │   └── content_list_page.dart     # Content listing with filters
│       ├── schedule/presentation/pages/
│       │   └── schedule_page.dart         # Calendar & timeline view
│       ├── analytics/presentation/pages/
│       │   └── analytics_page.dart        # Charts & insights
│       ├── subscription/presentation/pages/
│       │   └── subscription_page.dart      # Pricing & Razorpay
│       └── settings/presentation/pages/
│           └── settings_page.dart          # Profile & preferences
├── supabase/
│   ├── migrations/
│   │   └── 001_initial_schema.sql         # Full database schema
│   └── functions/
│       ├── generate-content/index.ts       # AI content generation
│       ├── generate-hashtags/index.ts      # Hashtag generation
│       ├── generate-image/index.ts         # DALL-E image generation
│       ├── create-order/index.ts           # Razorpay order creation
│       └── dashboard-stats/index.ts        # Analytics aggregation
├── pubspec.yaml                            # Dependencies
└── README.md                               # This file
```

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) >= 3.19
- [Supabase Account](https://supabase.com) (free tier works)
- [OpenAI API Key](https://platform.openai.com/api-keys)
- [Razorpay Account](https://razorpay.com) (for payments)

### 1. Clone & Install

```bash
git clone https://github.com/your-username/ViralFlowAutomation.git
cd ViralFlowAutomation
flutter pub get
```

### 2. Setup Supabase

1. Create a new Supabase project at [supabase.com](https://supabase.com)
2. Go to **SQL Editor** and run the migration file:
   ```sql
   -- Copy contents of supabase/migrations/001_initial_schema.sql
   ```
3. Go to **Project Settings > API** and copy your:
   - `Project URL` → `SUPABASE_URL`
   - `anon public` key → `SUPABASE_ANON_KEY`

### 3. Configure Environment

Edit `lib/core/config/env_config.dart`:

```dart
static const String supabaseUrl = 'https://your-project.supabase.co';
static const String supabaseAnonKey = 'your-anon-key';
static const String openaiApiKey = 'your-openai-key';
static const String razorpayKeyId = 'your-razorpay-key-id';
```

### 4. Deploy Edge Functions

Set secrets in Supabase:
```bash
supabase secrets set OPENAI_API_KEY=your-openai-key
supabase secrets set RAZORPAY_KEY_ID=your-razorpay-key
supabase secrets set RAZORPAY_KEY_SECRET=your-razorpay-secret
```

Deploy functions:
```bash
supabase functions deploy generate-content
supabase functions deploy generate-hashtags
supabase functions deploy generate-image
supabase functions deploy create-order
supabase functions deploy dashboard-stats
```

### 5. Run the App

```bash
flutter run
```

---

## 🗄️ Database Schema

### ER Diagram

```
┌──────────────┐     ┌──────────────┐     ┌──────────────────┐
│    users      │     │   contents   │     │  subscriptions   │
├──────────────┤     ├──────────────┤     ├──────────────────┤
│ id (PK)      │◄────│ user_id (FK) │     │ id (PK)          │
│ email        │     │ id (PK)      │     │ user_id (FK)     │
│ full_name    │     │ title        │     │ plan             │
│ plan         │     │ caption      │     │ status           │
│ credits      │     │ hashtags     │     │ amount           │
│ avatar_url   │     │ image_url    │     │ billing_cycle    │
│ referral_code│     │ content_type │     │ credits_per_month│
│ created_at   │     │ status       │     │ razorpay_*       │
└──────┬───────┘     │ platforms    │     └──────────────────┘
       │             │ scheduled_at │
       │             │ views/likes  │
       │             └──────────────┘
       │
       │     ┌──────────────────┐     ┌──────────────────┐
       │     │  connected_      │     │    analytics     │
       │     │  accounts        │     ├──────────────────┤
       ├────►│ id (PK)          │     │ id (PK)          │
       │     │ user_id (FK)     │     │ user_id (FK)     │
       │     │ platform         │     │ content_id (FK)  │
       │     │ access_token     │     │ platform         │
       │     │ is_active        │     │ event_type       │
       │     └──────────────────┘     │ event_date       │
       │                              └──────────────────┘
       │     ┌──────────────────┐
       └────►│   referrals      │
             ├──────────────────┤
             │ id (PK)          │
             │ referrer_id (FK) │
             │ referred_id (FK) │
             │ bonus_credits    │
             └──────────────────┘
```

### Row Level Security (RLS)

All tables have RLS enabled — users can only access their own data.

---

## 🤖 AI Features

### Content Generation Flow

```
User Prompt → Edge Function → OpenAI GPT-4o → Generated Content
                                    ↓
                              Credit Deduction
                                    ↓
                              Save to Database
```

### Supported Content Types

| Type | Platforms | Description |
|------|-----------|-------------|
| Post | Instagram, Facebook, LinkedIn | Standard social media post |
| Reel | Instagram, TikTok | Short video script & caption |
| Story | Instagram, Facebook | Ephemeral content |
| Thread | Twitter | Multi-tweet thread |
| Carousel | Instagram, LinkedIn | Multi-slide post |
| Tweet | Twitter | Single tweet |
| YT Short | YouTube | Short video script |
| Blog | LinkedIn | Long-form article |

### AI Tones

😊 Casual | 💼 Professional | 😂 Humorous | ✨ Inspirational | 📚 Educational | 🔥 Controversial

---

## 💳 Payment Integration

### Razorpay Flow

```
User Selects Plan → Create Order (Edge Function) → Razorpay Checkout
                                                          ↓
                                              Payment Success Callback
                                                          ↓
                                              Verify & Save Subscription
                                                          ↓
                                              Update User Plan & Credits
```

### Pricing (INR)

| Plan | Monthly | Yearly (Save 17%) |
|------|---------|-------------------|
| Free | ₹0 | ₹0 |
| Pro | ₹499 | ₹4,999 |
| Enterprise | ₹1,999 | ₹19,999 |

---

## 📊 Analytics Features

- **Views Over Time** — Line chart with daily/weekly/monthly views
- **Engagement Rate** — Bar chart showing engagement by day
- **Platform Performance** — Per-platform followers, posts, engagement
- **Best Posting Times** — AI-recommended optimal posting schedule
- **Content Recommendations** — AI-powered suggestions for content type
- **Audience Insights** — Demographics, active hours, growth rate
- **Top Performing Content** — Ranked by engagement metrics

---

## 🔐 Security

- **Row Level Security (RLS)** on all tables
- **JWT Authentication** via Supabase Auth
- **API Key Protection** — OpenAI keys stored as Supabase secrets
- **Input Validation** — Server-side validation in Edge Functions
- **Rate Limiting** — Credit system prevents abuse

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter 3.19+, Material 3 |
| State Management | Riverpod 2.5+ |
| Navigation | GoRouter 14+ |
| Backend | Supabase (PostgreSQL, Auth, Storage) |
| Serverless Functions | Supabase Edge Functions (Deno) |
| AI | OpenAI GPT-4o-mini, DALL-E 3 |
| Payments | Razorpay |
| Charts | fl_chart |
| Animations | flutter_animate |

---

## 📋 Roadmap

- [x] Phase 1: Core infrastructure & auth
- [x] Phase 2: AI content generation
- [x] Phase 3: Scheduling & calendar
- [x] Phase 4: Analytics dashboard
- [x] Phase 5: Subscription & payments
- [x] Phase 6: Settings & profile
- [ ] Phase 7: Social media OAuth & auto-posting
- [ ] Phase 8: Team collaboration (Enterprise)
- [ ] Phase 9: WhatsApp Business integration
- [ ] Phase 10: Mobile push notifications
- [ ] Phase 11: Content A/B testing
- [ ] Phase 12: White-label solution for agencies

---

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- [Flutter](https://flutter.dev) — Beautiful cross-platform UI
- [Supabase](https://supabase.com) — Open source Firebase alternative
- [OpenAI](https://openai.com) — GPT-4o & DALL-E 3 APIs
- [Razorpay](https://razorpay.com) — Payment gateway for India
- [fl_chart](https://github.com/imaNNeo/fl_chart) — Beautiful charts

---

**Built with ❤️ by the ViralFlow Team**