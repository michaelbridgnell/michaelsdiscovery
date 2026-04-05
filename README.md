# Sonik 🎵

An AI-powered music discovery iOS app. Sonik learns your sonic taste through swipe interactions and uses audio embeddings + collaborative filtering to surface tracks you'll actually like.

**Live backend:** https://michaelsdiscovery.onrender.com

---

## How it works

Traditional recommendation systems embed *metadata* (genre tags, artist similarity). Sonik embeds the *raw audio* itself.

1. **Audio embeddings** — each track's 30-second preview is passed through [LAION-CLAP](https://github.com/LAION-AI/CLAP), a contrastive neural network trained on 630k audio-text pairs. The output is a 512-dimensional vector encoding sonic content: timbre, rhythm, energy, instrumentation.

2. **Multi-capsule taste model** — instead of representing a user's taste as a single vector (which collapses multi-modal preferences into a meaningless centroid), taste is modelled as a mixture of K vectors — one per "sonic cluster" the user likes. Motivated by [arXiv:1904.08030](https://arxiv.org/pdf/1904.08030). Each like/dislike updates the nearest capsule via an online update rule.

3. **Hybrid recommendation** — final ranking is a weighted combination of:
   - Content-based score: cosine similarity between track embedding and user taste capsules
   - Collaborative score: user-user and item-item cosine similarity across all interactions

---

## Stack

| Layer | Tech |
|---|---|
| iOS | SwiftUI, AVFoundation, CoreLocation |
| Backend | Python, Flask, SQLAlchemy, Flask-Migrate |
| ML | LAION-CLAP (PyTorch), NumPy |
| Database | MySQL (Render) |
| Hosting | Render.com |
| Music data | Apple iTunes Search API |

---

## Features

- Tinder-style swipe UI with 30s audio previews and album art
- Personalised "For You" recommendations that improve with each swipe
- Community feed with location-based filtering (Nearby / Global)
- Friends system with taste sharing
- Password reset via email (SMTP)
- Rate limiting, auth tokens, profanity filtering

---

## Running locally

```bash
# Backend
pip install -r requirements.txt
flask --app flaskr db upgrade
flask --app flaskr run

# iOS
# Open MichaelsDiscovery.xcodeproj in Xcode and run on simulator
```

Set `CLAP_ENABLED=1` to enable audio embeddings (requires ~450MB RAM).

---

## Architecture note

The free hosting tier runs with `CLAP_ENABLED=0` — tracks are ranked by collaborative filtering alone. Setting `CLAP_ENABLED=1` on a paid tier activates full audio embedding generation, turning the recommender into a content-aware system that generalises to cold-start users with no interaction history.
