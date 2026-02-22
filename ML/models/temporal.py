import torch.nn as nn
import torch
import torch.nn.functional as F


# region ======== Version 1 ====================================

# class TemporalTransformer(nn.Module):

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

    # def __init__(self, dim=1280, hidden=512, layers=2, heads=8):
    #     super().__init__()

    #     self.proj = nn.Linear(dim, hidden)
    #     encoder_layer = nn.TransformerEncoderLayer(d_model=hidden, nhead=heads, batch_first=True)
    #     self.encoder = nn.TransformerEncoder(encoder_layer, num_layers=layers)

    # def forward(self,x):
    #     x = self.proj(x)
    #     x = self.encoder(x)
    #     return x.mean(dim=1)

# endregion

#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

# region ======== Version 2 ====================================


"""
    Postional encoder applied after results from first model. 
    """
# class TemporalTransformer(nn.Module):

    # def __init__(self, dim=1280, hidden=768, layers=3, heads=8, max_frames = 50):
    #     super().__init__()

    #     self.proj = nn.Linear(dim, hidden)
    #     encoder_layer = nn.TransformerEncoderLayer(d_model=hidden, nhead=heads, batch_first=True)
    #     self.encoder = nn.TransformerEncoder(encoder_layer, num_layers=layers)
    #     self.pos_encoding = nn.Parameter(torch.zeros(1, max_frames, hidden))

    # def forward(self,x):
    #     x = self.proj(x)
    #     x = x + self.pos_encoding[:, :x.size(1), :]
    #     x = self.encoder(x)
    #     return x.mean(dim=1)

# endregion

#---------------------------------------------------------------- FINAL VERSION --------------------------------------------------------------------------------------------------------------------------

"""
    Temporal attention pooling was added after resluts from shoplifting_model_v3.pth
    to mitigate impact of short lived motion artifacts by emphasizing semantically
    relevant frames. 
"""

class TemporalAttentionPooling(nn.Module):

    """
    Learning attention-based temporal pooling layer.

    Computes frame-wise attention weights across the temporal
    dimension and produces a weighted sum of frame features. 

    This allows the model to emphasize semantically important
    frames and suppress short-lived motion artifacts.

    Input:
        x: torch.Tensor
            Shape (B, T, H)
                B = batch size
                T = number of frames 
                H = hidden feature dimension

    Ouput:
        pooled: torch.Tensor 
            Shape (B, H)

    Notes:
        - Attention weights are normalized using softmax over time.
        - Designed to replace naive mean or max temporal pooling. 

    """

    def __init__(self, hidden):
        super().__init__()
        self.attn = nn.Linear(hidden, 1)

    def forward(self, x):
        weights = torch.softmax(self.attn(x).squeeze(-1), dim=1)
        out = (x * weights.unsqueeze(-1)).sum(dim=1)               
        return out

class TemporalTransformer(nn.Module):

    """

    Transformer-based temporal modeling module for
    video sequence representation learning.

    Projects per-frame spatial features into a hidden
    dimension, applies positional encoding, and models
    temporal dependancies using stacked Transformer encoder layers.
    Final sequence representation is aggregated using TemporalAttentionPooling.

    Parameters:

        dim: int
            Input feature dimension (from spatial encoder)

        hidden: int
            Transformer hidden dimension.

        layers: int
            Number of Transformer encoder layers

        heads: int
            Number of Transformer encoder layers

        max_frames: int
            Maximum supported sequence length for learnable positional
            encoding. 

    Input: 
        x: torch.Tensor
            Shape (B, T, dim)

    Output:
        features: torch.Tensor
            Shape (B, hidden)

    Notes:
        - Uses batch_first = True for transformer encoder.
        - Positional encoding is learnable.
        - Output is suitable for downstream classifier head. 

    """

    def __init__(self, dim=1280, hidden=768, layers=3, heads=8, max_frames = 50):
        super().__init__()

        self.proj = nn.Linear(dim, hidden)
        encoder_layer = nn.TransformerEncoderLayer(d_model=hidden, nhead=heads, batch_first=True)
        self.encoder = nn.TransformerEncoder(encoder_layer, num_layers=layers)
        self.pos_encoding = nn.Parameter(torch.zeros(1, max_frames, hidden))
        self.pool = TemporalAttentionPooling(hidden)

    def forward(self, x):
        x = self.proj(x)                  
        x = x + self.pos_encoding[:, :x.size(1), :]
        x = self.encoder(x)               
        x = self.pool(x)                  
        return x 