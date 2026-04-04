Building an AI-powered music recommendation app (targeting iOS and web) in Python. The core stack is:

music_api.py — searches iTunes API for songs and downloads 30-second .m4a previews
embeddings.py — loads the CLAP neural network (laion_clap) to convert audio previews into 512-dimensional vectors representing sonic content
taste.py — three classes: VectorTasteRecommender (user taste as a 512-dim vector updated by likes/dislikes), CollaborativeRecommender (user-user and item-item cosine similarity), and HybridRecommender (weighted combination of both)

Current task: connecting the three files so taste.py imports search_tracks from music_api.py and get_embedding from embeddings.py, replacing the fake np.random.randn(512) song vectors with real CLAP embeddings from live iTunes previews. Eventually want to upscale the database from the MySQL which you can see I currently have. Also am currently trying to replace single 512 dimension vector with what is described in this research paper: https://arxiv.org/pdf/1904.08030