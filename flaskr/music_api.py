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
    try:
        response = requests.get(url, params=params, timeout=10)
        response.raise_for_status()
        data = response.json()
    except Exception as e:
        print(f"[iTunes API error] {e}")
        return []

    tracks = []
    for item in data.get("results", []):
        preview_url = item.get("previewUrl")
        track_name  = item.get("trackName")
        artist_name = item.get("artistName")
        if not preview_url or not track_name or not artist_name:
            continue

        album_title = item.get("collectionName", "Unknown Album")
        try:
            # Use merge pattern to avoid duplicate key errors on PostgreSQL
            album_obj = Album.query.filter_by(title=album_title).first()
            if album_obj is None:
                album_obj = Album(title=album_title)
                db.session.add(album_obj)
                db.session.flush()
                print(f"[album] created: {album_title} id={album_obj.id}")

            existing_track = Track.query.filter_by(preview_url=preview_url).first()
            if existing_track is None:
                artwork = item.get("artworkUrl100", "")
                if artwork:
                    artwork = artwork.replace("100x100bb", "400x400bb")
                new_track = Track(
                    title=track_name,
                    artist=artist_name,
                    preview_url=preview_url,
                    album_id=album_obj.id,
                    artwork_url=artwork or None,
                )
                if _CLAP_ENABLED:
                    try:
                        from .embeddings import get_embedding
                        new_track.set_vector(get_embedding(preview_url))
                    except Exception as e:
                        print(f"[embedding skipped] {e}")
                db.session.add(new_track)
                db.session.flush()
                print(f"[track] created: {track_name} id={new_track.id}")
            else:
                new_track = existing_track
                print(f"[track] existing: {track_name} id={new_track.id}")

            tracks.append(new_track)
        except Exception as e:
            print(f"[track insert error] {e}")
            db.session.rollback()
            continue

    try:
        db.session.commit()
        print(f"[search_tracks] committed {len(tracks)} tracks")
    except Exception as e:
        print(f"[db commit error] {e}")
        db.session.rollback()

    return tracks

if __name__ == "__main__":
    results = search_tracks("radiohead")
    track = results[0]
    print(f'Downloading: {track["title"]} by {track["artist"]}')
    filepath = download_preview(track["preview_url"])
    print(f'Saved to: {filepath}')