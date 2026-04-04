from flask import Blueprint, jsonify, render_template, request

bp = Blueprint('main', __name__)

from . import db
from .music_api import search_tracks
from .models import Track, User, UserTaste, UserInteraction
from .taste import VectorTasteRecommender, CollaborativeRecommender, HybridRecommender


def _get_or_create_user(user_id):
    user = User.query.get(user_id)
    if user is None:
        user = User(id=user_id)
        db.session.add(user)
        db.session.commit()
    return user


def _load_taste(user_id, songs):
    """Load capsules from DB if they exist, otherwise start fresh."""
    taste_row = UserTaste.query.filter_by(user_id=user_id).first()
    if taste_row is not None:
        return VectorTasteRecommender(songs, existing_vectors=taste_row.get_vectors())
    return VectorTasteRecommender(songs)


def _save_taste(user_id, taste_model):
    """Persist updated capsules back to DB."""
    taste_row = UserTaste.query.filter_by(user_id=user_id).first()
    if taste_row is None:
        taste_row = UserTaste(user_id=user_id)
        db.session.add(taste_row)
    taste_row.set_vectors(taste_model.user_vectors)
    db.session.commit()


def _load_interactions(user_id):
    """Build the interactions dict from DB for CollaborativeRecommender."""
    all_interactions = UserInteraction.query.all()
    interactions = {}
    for row in all_interactions:
        track = Track.query.get(row.track_id)
        if track is None:
            continue
        key = f"user_{row.user_id}"
        interactions.setdefault(key, {})[track.title] = row.rating
    return interactions


@bp.route('/dashboard')
def dashboard():
    tracks = Track.query.all()
    return render_template('templates/dashboard.html', tracks=tracks)


@bp.route('/fetch-user-recommendations/<int:user_id>/<search_term>')
def fetch_recommendations(user_id, search_term):
    _get_or_create_user(user_id)

    tracks = search_tracks(search_term)

    songs = []
    for track in tracks:
        vec = track.get_vector()
        if vec is None:
            continue
        songs.append({"id": track.id, "title": track.title, "artist": track.artist, "vector": vec})

    if not songs:
        return jsonify([])

    user_key = f"user_{user_id}"
    taste_model = _load_taste(user_id, songs)
    cf_model = CollaborativeRecommender(_load_interactions(user_id))
    hybrid = HybridRecommender(taste_model, cf_model)

    results = hybrid.recommend(user_key, songs, top_k=5)

    return jsonify([
        {"id": s["id"], "title": s["title"], "artist": s["artist"], "score": round(score, 3)}
        for score, s in results
    ])


@bp.route('/like/<int:user_id>/<int:track_id>', methods=['POST'])
def like(user_id, track_id):
    return _record_feedback(user_id, track_id, rating=1)


@bp.route('/dislike/<int:user_id>/<int:track_id>', methods=['POST'])
def dislike(user_id, track_id):
    return _record_feedback(user_id, track_id, rating=-1)


def _record_feedback(user_id, track_id, rating):
    _get_or_create_user(user_id)
    track = Track.query.get(track_id)
    if track is None:
        return jsonify({"error": "track not found"}), 404

    # Update or create the interaction record
    interaction = UserInteraction.query.filter_by(user_id=user_id, track_id=track_id).first()
    if interaction is None:
        interaction = UserInteraction(user_id=user_id, track_id=track_id, rating=rating)
        db.session.add(interaction)
    else:
        interaction.rating = rating
    db.session.commit()

    # Update the user's taste capsules
    vec = track.get_vector()
    if vec is not None:
        taste_model = _load_taste(user_id, [])
        taste_model.update_user_vector(vec, liked=(rating == 1))
        _save_taste(user_id, taste_model)

    return jsonify({"status": "ok"})

# html to see what songs are there
# 
