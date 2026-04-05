import os
import requests

from . import db
from .models import Album, Track

# CLAP requires ~450 MB RAM. Only load it when CLAP_ENABLED=1 is set.
# On Render free tier leave this unset — tracks are saved without vectors
# and fetch_recommendations falls back to random ordering.
_CLAP_ENABLED = os.environ.get('CLAP_ENABLED', '0') == '1'

def download_preview(preview_url, filename="temp_preview.mp3"):
    response = requests.get(preview_url)
    with open(filename, "wb") as f:
        f.write(response.content)
    return filename

def search_tracks(query, limit=10):
    url = "https://itunes.apple.com/search"
    params = {
        "term": query,
        "media": "music",
        "limit": limit
    }
    response = requests.get(url, params=params)
    data = response.json()

    tracks = []
    for item in data["results"]:
        if not item.get("previewUrl"):
            continue

        album_title = item.get("collectionName", "Unknown Album")
        album_obj = Album.query.filter_by(title=album_title).first()
        if album_obj is None:
            album_obj = Album(title=album_title)
            db.session.add(album_obj)
            db.session.flush()  # get album_obj.id before committing

        existing_track = Track.query.filter_by(preview_url=item["previewUrl"]).first()
        if existing_track is None:
            artwork = item.get("artworkUrl100", "")
            if artwork:
                artwork = artwork.replace("100x100bb", "400x400bb")
            new_track = Track(
                title=item["trackName"],
                artist=item["artistName"],
                preview_url=item["previewUrl"],
                album_id=album_obj.id,
                artwork_url=artwork or None,
            )
            if _CLAP_ENABLED:
                try:
                    from .embeddings import get_embedding
                    new_track.set_vector(get_embedding(item["previewUrl"]))
                except Exception as e:
                    print(f"[embedding skipped] {e}")
            db.session.add(new_track)
        else:
            new_track = existing_track

        tracks.append(new_track)

    db.session.commit()
    return tracks

if __name__ == "__main__":
    results = search_tracks("radiohead")
    track = results[0]
    print(f'Downloading: {track["title"]} by {track["artist"]}')
    filepath = download_preview(track["preview_url"])
    print(f'Saved to: {filepath}')