import numpy as np
from flaskr import db

class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)

class UserTaste(db.Model):
    """Stores a user's K capsule vectors as bytes."""
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False, unique=True)
    capsules = db.Column(db.LargeBinary, nullable=False)  # shape (K, 512)
    K = db.Column(db.Integer, nullable=False, default=4)

    def get_vectors(self):
        arr = np.frombuffer(self.capsules, dtype=np.float32)
        return arr.reshape(self.K, -1)

    def set_vectors(self, matrix):
        self.K = matrix.shape[0]
        self.capsules = matrix.astype(np.float32).tobytes()

class UserInteraction(db.Model):
    """Stores every like/dislike a user has made."""
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    track_id = db.Column(db.Integer, db.ForeignKey('track.id'), nullable=False)
    rating = db.Column(db.Integer, nullable=False)  # +1 liked, -1 disliked

class Album(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(255), nullable=False)

class Track(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(255), nullable=False)
    artist = db.Column(db.String(255), nullable=False)
    preview_url = db.Column(db.String(255), nullable=False)
    album_id = db.Column(db.Integer, db.ForeignKey('album.id'), nullable=False)
    embedding = db.Column(db.LargeBinary, nullable=True)  # 512-dim CLAP vector stored as bytes

    def get_vector(self):
        if self.embedding is None:
            return None
        return np.frombuffer(self.embedding, dtype=np.float32)

    def set_vector(self, vec):
        self.embedding = vec.astype(np.float32).tobytes()
    
