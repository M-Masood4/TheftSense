import torch.nn as nn

class TemporalTransformer(nn.Module):

    """
    Models temporal dependencies between frame-level features using
    a Transformer encoder. 

    This module captures long-range temporal patterns and behavioural 
    dynamics across a video clip.

    Architecture:
    - Linear projection: 1280 -> 512
    - Transformer Encoder
        - Multi-head self-attention
        - Feed-forward layers
        - Residual connections 
        - Layer normalization 
    - Temporal pooling (mean)

    Input
    x : torch.Tensor
        Shape: (B, T, D)
        - B: batch size
        - T: number of frames
        - D: feature dimension (1280 from CNN)

    Output
    
    clip_embedding: torch.Tensor
        Shape: (B, 512)
        A fixed-length representation of the entire clip. 

    Notes

    - Self-attention allows each frame to attend to all others.
    - Mean pooling provides a stable clip-level representation.
    - Attention weights can be extracted for temporal analysis and interperability 
        
    """

    def __init__(self, dim=1280, hidden=512, layers=2, heads=8):
        super().__init__()

        self.proj = nn.Linear(dim, hidden)
        encoder_layer = nn.TransformerEncoderLayer(d_model=hidden, nhead=heads, batch_first=True)
        self.encoder = nn.TransformerEncoder(encoder_layer, num_layers=layers)

    def forward(self,x):
        x = self.proj(x)
        x = self.encoder(x)
        return x.mean(dim=1)