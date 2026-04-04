import numpy as np
from .music_api import search_tracks, download_preview
import os

_model = None

def _get_model():
    global _model
    if _model is None:
        import laion_clap
        _model = laion_clap.CLAP_Module(enable_fusion=False)
        _model.load_ckpt()
    return _model

def get_embedding(preview_url):
    filepath = os.path.join(os.path.dirname(__file__), "temp_preview.m4a")
    download_preview(preview_url, filename=filepath)
    
    print(f"File size: {os.path.getsize(filepath)} bytes")
    
    embedding = _get_model().get_audio_embedding_from_filelist(
        [filepath], use_tensor=False
    )
    
    os.remove(filepath)
    
    vec = embedding[0]
    vec /= np.linalg.norm(vec)
    return vec

if __name__ == "__main__":
    results = search_tracks("radiohead", limit=3)
    
    for track in results:
        print(f'Getting embedding for: {track["title"]}')
        vec = get_embedding(track["preview_url"])
        track["vector"] = vec
        print(f'  Vector shape: {vec.shape}')
        print(f'  First 5 dims: {vec[:5]}\n')