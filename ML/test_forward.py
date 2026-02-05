import torch
from models.model import ShopliftingModel

model = ShopliftingModel().cuda()
dummy = torch.randn(2, 50, 3, 224, 224).cuda()

out = model(dummy)
print(out.shape)
