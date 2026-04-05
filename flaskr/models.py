import numpy as np
from datetime import datetime, timezone
from flaskr import db


class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    email = db.Column(db.String(255), unique=True, nullable=True)
    password_hash = db.Column(db.String(255), nullable=False)


class UserToken(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    token = db.Column(db.String(64), unique=True, nullable=False)


class UserTaste(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False, unique=True)
    capsules = db.Column(db.LargeBinary, nullable=False)
    K = db.Column(db.Integer, nullable=False, default=4)

    def get_vectors(self):
        arr = np.frombuffer(self.capsules, dtype=np.float32)
        return arr.reshape(self.K, -1)

    def set_vectors(self, matrix):
        self.K = matrix.shape[0]
        self.capsules = matrix.astype(np.float32).tobytes()


class UserInteraction(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    track_id = db.Column(db.Integer, db.ForeignKey('track.id'), nullable=False)
    rating = db.Column(db.Integer, nullable=False)  # +1 liked, -1 disliked


class Friendship(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    requester_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    receiver_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    accepted = db.Column(db.Boolean, default=False, nullable=False)


class Post(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    username = db.Column(db.String(80), nullable=False)  # denormalized for fast display
    content = db.Column(db.String(280), nullable=False)
    category = db.Column(db.String(50), nullable=False, default='General')
    created_at = db.Column(db.DateTime, nullable=False, default=lambda: datetime.now(timezone.utc))


class PasswordResetCode(db.Model):
    """Single-use 6-digit code for password reset. Expires in 15 minutes."""
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    code = db.Column(db.String(6), nullable=False)
    expires_at = db.Column(db.DateTime(timezone=True), nullable=False)
    used = db.Column(db.Boolean, default=False, nullable=False)


class Album(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(255), nullable=False)


class Track(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(255), nullable=False)
    artist = db.Column(db.String(255), nullable=False)
    preview_url = db.Column(db.String(255), nullable=False)
    album_id = db.Column(db.Integer, db.ForeignKey('album.id'), nullable=False)
    embedding = db.Column(db.LargeBinary, nullable=True)

    def get_vector(self):
        if self.embedding is None:
            return None
        return np.frombuffer(self.embedding, dtype=np.float32)

    def set_vector(self, vec):
        self.embedding = vec.astype(np.float32).tobytes()
