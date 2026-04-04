import re
import secrets
from functools import wraps

from flask import Blueprint, jsonify, request
from werkzeug.security import generate_password_hash, check_password_hash

from . import db, limiter
from .music_api import search_tracks
from .models import Track, User, UserToken, UserTaste, UserInteraction, Friendship
from .taste import VectorTasteRecommender, CollaborativeRecommender, HybridRecommender

bp = Blueprint('main', __name__)

USERNAME_RE = re.compile(r'^[a-zA-Z0-9_]{3,50}$')


# --------------------------------------------------
# Auth helpers
# --------------------------------------------------

def _get_current_user():
    auth = request.headers.get('Authorization', '')
    if not auth.startswith('Bearer '):
        return None
    token_str = auth[7:]
    token = UserToken.query.filter_by(token=token_str).first()
    if token is None:
        return None
    return User.query.get(token.user_id)

def require_auth(f):
    @wraps(f)
    def wrapper(*args, **kwargs):
        user = _get_current_user()
        if user is None:
            return jsonify({"error": "unauthorized"}), 401
        return f(user, *args, **kwargs)
    return wrapper


# --------------------------------------------------
# Taste helpers
# --------------------------------------------------

def _load_taste(user_id, songs):
    taste_row = UserTaste.query.filter_by(user_id=user_id).first()
    if taste_row is not None:
        return VectorTasteRecommender(songs, existing_vectors=taste_row.get_vectors())
    return VectorTasteRecommender(songs)

def _save_taste(user_id, taste_model):
    taste_row = UserTaste.query.filter_by(user_id=user_id).first()
    if taste_row is None:
        taste_row = UserTaste(user_id=user_id)
        db.session.add(taste_row)
    taste_row.set_vectors(taste_model.user_vectors)
    db.session.commit()

def _load_interactions(user_id):
    all_interactions = UserInteraction.query.all()
    interactions = {}
    for row in all_interactions:
        track = Track.query.get(row.track_id)
        if track is None:
            continue
        key = f"user_{row.user_id}"
        interactions.setdefault(key, {})[track.title] = row.rating
    return interactions

def _record_feedback(user_id, track_id, rating):
    track = Track.query.get(track_id)
    if track is None:
        return jsonify({"error": "track not found"}), 404
    interaction = UserInteraction.query.filter_by(user_id=user_id, track_id=track_id).first()
    if interaction is None:
        interaction = UserInteraction(user_id=user_id, track_id=track_id, rating=rating)
        db.session.add(interaction)
    else:
        interaction.rating = rating
    db.session.commit()
    vec = track.get_vector()
    if vec is not None:
        taste_model = _load_taste(user_id, [])
        taste_model.update_user_vector(vec, liked=(rating == 1))
        _save_taste(user_id, taste_model)
    return jsonify({"status": "ok"})


# --------------------------------------------------
# Auth endpoints
# --------------------------------------------------

@bp.route('/register', methods=['POST'])
@limiter.limit("5 per minute")
def register():
    data = request.get_json(silent=True) or {}
    username = data.get('username', '').strip()[:50]
    password = data.get('password', '')[:100]
    if not username or not password:
        return jsonify({"error": "username and password required"}), 400
    if not USERNAME_RE.match(username):
        return jsonify({"error": "username must be 3-50 characters, letters/numbers/underscores only"}), 400
    if len(password) < 8:
        return jsonify({"error": "password must be at least 8 characters"}), 400
    if User.query.filter_by(username=username).first():
        return jsonify({"error": "username taken"}), 409
    user = User(username=username, password_hash=generate_password_hash(password))
    db.session.add(user)
    db.session.commit()
    token_str = secrets.token_hex(32)
    db.session.add(UserToken(user_id=user.id, token=token_str))
    db.session.commit()
    return jsonify({"user_id": user.id, "token": token_str}), 201


@bp.route('/login', methods=['POST'])
@limiter.limit("10 per minute")
def login():
    data = request.get_json(silent=True) or {}
    username = data.get('username', '').strip()[:50]
    password = data.get('password', '')[:100]
    if not username or not password:
        return jsonify({"error": "username and password required"}), 400
    user = User.query.filter_by(username=username).first()
    # Constant-time check even on missing user to prevent user enumeration
    if user is None or not check_password_hash(user.password_hash, password):
        return jsonify({"error": "invalid credentials"}), 401
    token_str = secrets.token_hex(32)
    db.session.add(UserToken(user_id=user.id, token=token_str))
    db.session.commit()
    return jsonify({"user_id": user.id, "token": token_str})


# --------------------------------------------------
# Onboarding — seed taste from known songs
# --------------------------------------------------

@bp.route('/seed', methods=['POST'])
@require_auth
@limiter.limit("5 per minute")
def seed(current_user):
    data = request.get_json(silent=True) or {}
    titles = [str(t).strip()[:200] for t in data.get('titles', []) if str(t).strip()]
    if len(titles) < 3:
        return jsonify({"error": "provide at least 3 song titles"}), 400
    taste_model = _load_taste(current_user.id, [])
    seeded = 0
    for title in titles:
        tracks = search_tracks(title, limit=1)
        if not tracks:
            continue
        vec = tracks[0].get_vector()
        if vec is None:
            continue
        taste_model.update_user_vector(vec, liked=True)
        seeded += 1
    _save_taste(current_user.id, taste_model)
    return jsonify({"seeded": seeded})


# --------------------------------------------------
# Recommendations
# --------------------------------------------------

@bp.route('/recommendations/<search_term>')
@require_auth
@limiter.limit("30 per minute")
def fetch_recommendations(current_user, search_term):
    search_term = search_term.strip()[:100]
    tracks = search_tracks(search_term)
    songs = []
    for track in tracks:
        vec = track.get_vector()
        if vec is None:
            continue
        songs.append({"id": track.id, "title": track.title, "artist": track.artist,
                       "preview_url": track.preview_url, "vector": vec})
    if not songs:
        return jsonify([])
    user_key = f"user_{current_user.id}"
    taste_model = _load_taste(current_user.id, songs)
    cf_model = CollaborativeRecommender(_load_interactions(current_user.id))
    hybrid = HybridRecommender(taste_model, cf_model)
    results = hybrid.recommend(user_key, songs, top_k=10)
    return jsonify([
        {"id": s["id"], "title": s["title"], "artist": s["artist"],
         "preview_url": s["preview_url"], "score": round(score, 3)}
        for score, s in results
    ])


# --------------------------------------------------
# Swipe (like/dislike)
# --------------------------------------------------

@bp.route('/swipe/<int:track_id>', methods=['POST'])
@require_auth
@limiter.limit("60 per minute")
def swipe(current_user, track_id):
    data = request.get_json(silent=True) or {}
    direction = data.get('direction')
    if direction not in ('like', 'dislike'):
        return jsonify({"error": "direction must be like or dislike"}), 400
    rating = 1 if direction == 'like' else -1
    return _record_feedback(current_user.id, track_id, rating)


# --------------------------------------------------
# Community / Friends
# --------------------------------------------------

@bp.route('/friends', methods=['GET'])
@require_auth
def get_friends(current_user):
    friendships = Friendship.query.filter(
        ((Friendship.requester_id == current_user.id) | (Friendship.receiver_id == current_user.id)),
        Friendship.accepted == True
    ).all()
    friends = []
    for f in friendships:
        friend_id = f.receiver_id if f.requester_id == current_user.id else f.requester_id
        friend = User.query.get(friend_id)
        if friend:
            friends.append({"user_id": friend.id, "username": friend.username})
    return jsonify(friends)


@bp.route('/friends/requests', methods=['GET'])
@require_auth
def get_friend_requests(current_user):
    requests_list = Friendship.query.filter_by(receiver_id=current_user.id, accepted=False).all()
    return jsonify([
        {"friendship_id": f.id, "from_user_id": f.requester_id,
         "username": User.query.get(f.requester_id).username}
        for f in requests_list
    ])


@bp.route('/friends/add', methods=['POST'])
@require_auth
@limiter.limit("20 per minute")
def add_friend(current_user):
    data = request.get_json(silent=True) or {}
    username = data.get('username', '').strip()[:50]
    if not username:
        return jsonify({"error": "username required"}), 400
    target = User.query.filter_by(username=username).first()
    if target is None:
        return jsonify({"error": "user not found"}), 404
    if target.id == current_user.id:
        return jsonify({"error": "cannot add yourself"}), 400
    existing = Friendship.query.filter_by(requester_id=current_user.id, receiver_id=target.id).first()
    if existing:
        return jsonify({"error": "request already sent"}), 409
    db.session.add(Friendship(requester_id=current_user.id, receiver_id=target.id))
    db.session.commit()
    return jsonify({"status": "request sent"})


@bp.route('/friends/accept/<int:friendship_id>', methods=['POST'])
@require_auth
def accept_friend(current_user, friendship_id):
    friendship = Friendship.query.get(friendship_id)
    if friendship is None or friendship.receiver_id != current_user.id:
        return jsonify({"error": "not found"}), 404
    friendship.accepted = True
    db.session.commit()
    return jsonify({"status": "accepted"})


@bp.route('/friends/<int:friend_id>/taste', methods=['GET'])
@require_auth
def friend_taste(current_user, friend_id):
    is_friends = Friendship.query.filter(
        ((Friendship.requester_id == current_user.id) & (Friendship.receiver_id == friend_id)) |
        ((Friendship.requester_id == friend_id) & (Friendship.receiver_id == current_user.id)),
        Friendship.accepted == True
    ).first()
    if not is_friends:
        return jsonify({"error": "not friends"}), 403
    liked = UserInteraction.query.filter_by(user_id=friend_id, rating=1).all()
    result = []
    for interaction in liked:
        track = Track.query.get(interaction.track_id)
        if track:
            result.append({"title": track.title, "artist": track.artist})
    return jsonify(result)


@bp.route('/me/likes', methods=['GET'])
@require_auth
def my_likes(current_user):
    liked = UserInteraction.query.filter_by(user_id=current_user.id, rating=1).all()
    result = []
    for interaction in liked:
        track = Track.query.get(interaction.track_id)
        if track:
            result.append({"title": track.title, "artist": track.artist})
    return jsonify(result)
