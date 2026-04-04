# taste.py
# Core AI-style taste-based recommendation engine (no UI, no Swift)
# Updated to use vector-based taste representation (ready for embeddings like CLAP)

import math

import numpy as np
from .embeddings import get_embedding
from .music_api import search_tracks

# --------------------------------------------------
# Fake song database (stand-in for real data)
# --------------------------------------------------
# Will eventually be a large database of songs, maybe integrate SQL
# Each song now has a "vector" key instead of taste axes
#IS 512 dimensions necessary to match CLAP?""


songs = [
    {
        "title": "Night Drive",
        "artist": "Fake Artist A",
        "vector": np.random.randn(512),  # placeholder vector
    },
    {
        "title": "Neon Pulse",
        "artist": "Fake Artist B",
        "vector": np.random.randn(512),
    },
    {
        "title": "Quiet Morning",
        "artist": "Fake Artist C",
        "vector": np.random.randn(512),
    },
    {
        "title": "Static Memory",
        "artist": "Fake Artist D",
        "vector": np.random.randn(512),
    },
]

# Normalize vectors so magnitude = 1 (common for embeddings)
for song in songs:
    song["vector"] /= np.linalg.norm(song["vector"])

# user_id -> { song_title -> +1 / -1 }
#liked or didn't like?
user_interactions = {
    "user_1": {
        "Night Drive": 1,
        "Neon Pulse": -1,
    },
    "user_2": {
        "Neon Pulse": 1,
        "Static Memory": 1,
    },
}

# --------------------------------------------------
# Vector-based TasteRecommender class
# --------------------------------------------------
# Object here represents a user's taste model
# Uses 512-dim (or any N-dim) vectors instead of manual taste axes
class VectorTasteRecommender:
    def __init__(self, songs, vector_dim=512, K=4, existing_vectors=None):
        self.songs = songs
        self.vector_dim = vector_dim
        self.K = K

        if existing_vectors is not None:
            self.user_vectors = existing_vectors
        else:
            self.user_vectors = np.random.randn(K, vector_dim)
            self.user_vectors /= np.linalg.norm(self.user_vectors, axis=1, keepdims=True)

    # Route song to its closest interest capsule, return capsule index and similarity
    def _route(self, song_vector):
        sims = self.user_vectors @ song_vector  # (K,)
        return np.argmax(sims), sims

    # Score = max cosine similarity across all K interest capsules (label-aware attention)
    def taste_score(self, song):
        _, sims = self._route(song["vector"])
        return float(np.max(sims))

    # Update only the best-matching capsule toward/away from the song
    def update_user_vector(self, song_vector, liked=True, lr=0.1):
        best_k, _ = self._route(song_vector)
        direction = 1 if liked else -1
        self.user_vectors[best_k] += direction * lr * (song_vector - self.user_vectors[best_k])
        self.user_vectors[best_k] /= np.linalg.norm(self.user_vectors[best_k])

    # fit() kept for API compatibility — delegates to update_user_vector
    def fit(self, song_vector, liked=True, lr=0.05):
        self.update_user_vector(song_vector, liked=liked, lr=lr)

    # Recommends top_k songs by best capsule match
    def recommend(self, top_k=3):
        scored = []
        for song in self.songs:
            score = self.taste_score(song)
            scored.append((score, song))
        scored.sort(key=lambda x: x[0], reverse=True)
        return scored[:top_k]

# --------------------------------------------------
# CollaborativeRecommender (unchanged)
# --------------------------------------------------
class CollaborativeRecommender:
    def __init__(self, interactions):
        self.interactions = interactions

#user similarity using cosine similarity formula
#takes two user's ratings dicts
    def user_similarity(self, u1, u2):
        common = set(u1) & set(u2)
        if not common:
            return 0.0
        dot = sum(u1[s] * u2[s] for s in common)
        norm1 = math.sqrt(sum(v*v for v in u1.values()))
        norm2 = math.sqrt(sum(v*v for v in u2.values()))
        return dot / (norm1 * norm2)

    def user_cf_score(self, target_user, song_title):
        if target_user not in self.interactions:
            return 0.0
        score = 0.0
        total_sim = 0.0
        for other_user, ratings in self.interactions.items():
            if song_title not in ratings:
                continue
            sim = self.user_similarity(
                self.interactions[target_user],
                ratings
            )
            score += sim * ratings[song_title]
            total_sim += abs(sim)
        return score / total_sim if total_sim > 0 else 0.0
    #weighted average
    #How much will target user like song s
    #Average total score 
    #self is just an object which accesses the entire interactions dict with many users

    def item_similarity(self, song_a, song_b):
        vec_a, vec_b = [], []
        for user, ratings in self.interactions.items():
            if song_a in ratings and song_b in ratings:
                vec_a.append(ratings[song_a])
                vec_b.append(ratings[song_b])
        if not vec_a:
            return 0.0
        dot = sum(a*b for a,b in zip(vec_a, vec_b))
        norm_a = math.sqrt(sum(a*a for a in vec_a))
        norm_b = math.sqrt(sum(b*b for b in vec_b))
        return dot / (norm_a * norm_b)

    def item_cf_score(self, user_id, song_title):
        if user_id not in self.interactions:
            return 0.0
        score = 0.0
        total_sim = 0.0
        for liked_song, rating in self.interactions[user_id].items():
            sim = self.item_similarity(liked_song, song_title)
            score += sim * rating
            total_sim += np.abs(sim)
        return score / total_sim if total_sim > 0 else 0.0

#how similar is this song to songs this user has liked


# --------------------------------------------------
# HybridRecommender (unchanged)
# --------------------------------------------------

#no soloing in on one user only
class HybridRecommender:
    def __init__(self, taste_model, cf_model,
                 alpha=0.5, beta=0.25, gamma=0.25):
        self.taste_model = taste_model
        self.cf_model = cf_model
        self.alpha = alpha
        self.beta = beta
        self.gamma = gamma
#to understand still
    def recommend(self, user_id, songs, top_k=5):
        scored = []
        for song in songs:
            taste = self.taste_model.taste_score(song)
            user_cf = self.cf_model.user_cf_score(user_id, song["title"])
            item_cf = self.cf_model.item_cf_score(user_id, song["title"])
            final = (
                self.alpha * taste +
                self.beta * user_cf +
                self.gamma * item_cf
            )
            scored.append((final, song))
        scored.sort(key=lambda x: x[0], reverse=True)
        return scored[:top_k]

# --------------------------------------------------
# Manual test run
# --------------------------------------------------
if __name__ == "__main__":
    # Initialize user's vector-based taste model
    engine = VectorTasteRecommender(songs, K=4)
    print(f"Initial interest capsules shape: {engine.user_vectors.shape}\n")

    results = engine.recommend(top_k=3)
    print("\nRecommended songs:\n")
    for score, song in results:
        print(f'{song["title"]} by {song["artist"]} (score={score:.3f})')

    # Simulate user feedback (like top song)
    score, song = results[0]
    engine.update_user_vector(song["vector"], liked=True)

    print("\nUpdated interest capsules (first 5 dims of each):")
    for i, vec in enumerate(engine.user_vectors):
        print(f"  Capsule {i}: {vec[:5]}")
