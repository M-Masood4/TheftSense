import torch.nn as nn
import timm 

class SpatialEncoder(nn.Module):

    """
    Extracts per-frame spatial features from video clips
    using a pretrained EfficientNetV2 backbone.

    This module operates independently on each frame and 
    does not model temporal relationships.

    Architecture
    EfficientNetV2-S (ImageNet pretrained)
        - Classifier head removed
        - Output: 1280-dimensional feature vector per frame

    Input
    x : torch.Tensor
        Shape: (B, T, C, H, W)
        - B: Batch size
        - T: number of frames per clip
        - C: number of channels (RGB = 3)
        - H,W: spatial resolution (224x224)

    Output
    features : torch.Tensor
        Shape: (B,T,D)
        - D = 1280 for EfficientNetV2-S

    Notes
        - Frames are processed independently 
        - Time dimension is temporarily folded into batch for efficient GPU execution.
        - Pretrained weights accelerate convergence and improve generalization on small datasets. 

    """

    def __init__(self):

        """
        Standard PyTorch boilerplate.

        - Loads EfficientV2-S
        - Uses ImageNet pretrained weights
        - Removes the classifier head (num_classes = 0)

        Model outputs features and not predictions
        """

        super().__init__()
        self.backbone = timm.create_model(
            "tf_efficientnetv2_s",
            pretrained=True, 
            num_classes = 0
        )

    def forward(self, x):

        """
        Input shape is (Batch, Time, Channels, Heights, Width)

        Returns each video clip as a sequence of frame embedings. 
        """

        B, T, C, H, W = x.shape
        x = x.view(B*T, C, H, W)
        features = self.backbone(x)
        return features.view(B, T, -1)