import torch
import torch.nn as nn
import torch.nn.functional as F

class RespiratoryCNN(nn.Module):
    def __init__(self):
        super(RespiratoryCNN, self).__init__()
        
        # Input: (Batch, 1, 40, 157)
        
        # Conv Block 1
        self.conv1 = nn.Conv2d(1, 32, kernel_size=3, padding=1)
        self.bn1 = nn.BatchNorm2d(32)
        self.pool1 = nn.MaxPool2d(2, 2) # -> (32, 20, 78)
        
        # Conv Block 2
        self.conv2 = nn.Conv2d(32, 64, kernel_size=3, padding=1)
        self.bn2 = nn.BatchNorm2d(64)
        self.pool2 = nn.MaxPool2d(2, 2) # -> (64, 10, 39)
        
        # Conv Block 3
        self.conv3 = nn.Conv2d(64, 128, kernel_size=3, padding=1)
        self.bn3 = nn.BatchNorm2d(128)
        self.pool3 = nn.MaxPool2d(2, 2) # -> (128, 5, 19)
        
        # Fully Connected
        # Flatten: 128 * 5 * 19 = 12160
        self.fc1 = nn.Linear(12160, 512)
        self.dropout = nn.Dropout(0.5)
        self.fc2 = nn.Linear(512, 1) # Binary Classification / Risk Score (Sigmoid)

    def forward(self, x):
        # x: (Batch, 1, MFCC, Time)
        
        x = self.pool1(F.relu(self.bn1(self.conv1(x))))
        x = self.pool2(F.relu(self.bn2(self.conv2(x))))
        x = self.pool3(F.relu(self.bn3(self.conv3(x))))
        
        x = x.view(x.size(0), -1) # Flatten
        
        x = F.relu(self.fc1(x))
        features = x  # Save features for Stage 2
        x = self.dropout(x)
        risk = torch.sigmoid(self.fc2(x)) # Output 0-1
        
        return risk, features
