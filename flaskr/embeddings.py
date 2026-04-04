import numpy as np
import laion_clap
from .music_api import search_tracks, download_preview
import os

print("Loading CLAP model...")
model = laion_clap.CLAP_Module(enable_fusion=False)
model.load_ckpt()
print("CLAP ready\n")

def get_embedding(preview_url):
    filepath = os.path.join(os.path.dirname(__file__), "temp_preview.m4a")
    download_preview(preview_url, filename=filepath)
    
    print(f"File size: {os.path.getsize(filepath)} bytes")
    
    embedding = model.get_audio_embedding_from_filelist(
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