import torch
import torch.nn as nn
import torch.nn.functional as F

class DiseaseClassifier(nn.Module):
    def __init__(self, input_dim=512, num_classes=5):
        super(DiseaseClassifier, self).__init__()
        
        # Stage 1 outputs a 512-dim vector
        self.input_dim = input_dim
        
        # Lightweight MLP Head
        self.fc1 = nn.Linear(input_dim, 128)
        self.bn1 = nn.BatchNorm1d(128)
        self.dropout = nn.Dropout(0.3)
        self.fc2 = nn.Linear(128, num_classes)
        
        self.classes = ["Normal", "Asthma", "COPD", "Pneumonia", "Other"]

    def forward(self, x):
        # x: (Batch, 512)
        
        x = F.relu(self.bn1(self.fc1(x)))
        x = self.dropout(x)
        logits = self.fc2(x)
        
        return logits

    def predict_probs(self, x):
        """Helper for inference to get actual probabilities"""
        logits = self.forward(x)
        return F.softmax(logits, dim=1)
