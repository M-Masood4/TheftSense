import torch
import numpy as np 
import matplotlib.pyplot as plt 
import cv2 
from models.model import ShopliftingModel
from data.dataset import VideoDataset

DEVICE = "cuda"
MODEL_PATH = "shoplifting_model.pth"
VIDEO_PATH = "sample_clip.mp4"
NUM_FRAMES = 50

class GradCam:

    """
    This module provides visual explanations of model predictions
    using Gradient-weighted Class Activation Mapping (Grad-CAM).

    Purpose
        - Identify spatial regions influencing model decisions
        - Validate that predictions are based on meaningful behavior
        - Detecting shortcut learning or dataset bias
        - Improve trust and interpretability

    Method
        - Gradients are extracted from the final convolutional layer
        - Feature maps are weighted by gradient importance
        - A class-specific activation map is generated
        - Heatmaps are overlaid on original video frames

    Scope
        - Explains spatial attention per frame
        - Temporal reasoning is handled by the Transformer end
          is not directly visualized here.

    Notes
        - Analysis is performed on individual clips 
        - Grad-CAM is used only for diagnostics 
        - No training parameters are modified.
    """

    def __init__(self, model, target_layer):
        self.model = model
        self.target_layer = target_layer
        self.gradients = None
        self.activations = None

        target_layer.register_forward_hook(self.save_activation)
        target_layer.register_backward_hook(self.save_gradient)

    def save_activation(self, module, input, output):
        self.activations = output.detach()

    def save_gradient(self, module, grad_input, grad_output):
        self.gradients = grad_output[0].detach()

    def generate(self):
        weights = self.gradients.mean(dim=(2,3), keepdim=True)
        cam = (weights * self.activations).sum(dim=1)
        cam = torch.relu(cam)
        cam = cam - cam.min()
        cam = cam / (cam.max() + 1e-8)
        return cam
    
def overlay_cam(frame, cam):
    cam = cv2.resize(cam, (frame.shape[1], frame.shape[0]))
    heatmap = cv2.applyColorMap(np.unit8(255*cam), cv2.COLORMAP_JET)
    return cv2.addWeighted(frame, 0.6, heatmap, 0.4, 0)

if __name__ == "__main__":
    model = ShopliftingModel().to(DEVICE)
    model.load_state_dict(torch.load(MODEL_PATH))
    model.eval()

    target_layer = model.spatial.backbone.blocks[-1]

    gradcam = GradCam(model, target_layer)

    dataset = VideoDataset.from_single_video(VIDEO_PATH, NUM_FRAMES)

    video, _ = dataset[0]
    video = video.unsqeeze(0).to(DEVICE)

    logits = model(video)
    logits.backward()

    cam = gradcam.generate()[0]

    mid = NUM_FRAMES // 2
    frame = video[0, mid].permute(1,2,0).cpu().numpy()
    frame = (frame*255).astype(np.uint8)

    cam_overlay = overlay_cam(frame, cam[mid].cpu().numpy())

    plt.imshow(cam_overlay)
    plt.title("Grad-CAM Visualization")
    plt.axis("off")
    plt.show()