import torch.nn as nn
from models.spatial import SpatialEncoder
from models.temporal import TemporalTransformer

class ShopliftingModel(nn.Module):

    """
    End-to-end spatiotemporal model for shoplifting detection.

    The model combines:
        1. A CNN-based spatial encoder for per-frame understanding.
        2. A Transformer-based temporal encoder for behaviour modeling.
        3. A lightweight classifier head for binary prediction.

    Architecture
    Input: Video clip (T frames)

    1. SpatialEncoder
        - EfficientNetV2 backbone
        - Outputs frame-level features
    
    2. TemporalTransformer
        - Models long-range temporal dependancies
        - Produces a single clip-level embedding
    
    3. Classifier Head
        - Fully connected layers
        - Outputs a binary logit

    Input

    x: torch.Tensor
    Shape: (B, T, 3, 224, 224)

    Output
    logits: torch.Tensor
            Shape: (B,)
            Raw prediction scores for binary classification.

    Notes
    - Sigmoid activation is applied externally.
    - Designed for clip-level classification.
    - Modular design allows easy replacement of spatial or temporal components.  
    """

    def __init__(self):
        super().__init__()

        self.spatial = SpatialEncoder()
        self.temporal = TemporalTransformer()

        self.classifier = nn.Sequential(
            nn.Linear(512,128),
            nn.ReLU(),
            nn.Dropout(0.3),
            nn.Linear(128,1)
        )

    def forward(self, x):
        x = self.spatial(x)
        x = self.temporal(x)
        return self.classifier(x).squeeze(1)