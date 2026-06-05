import os
import json
from constants import PROJECT_DIR

class PresetsManager:
    """Manages loading and retrieval of focus presets."""
    def __init__(self):
        self.presets = []
        self.presets_names = []
        self.load_presets()
        
    def load_presets(self):
        presets_file = os.path.join(PROJECT_DIR, "presets", "presets.json")
        if os.path.exists(presets_file):
            try:
                with open(presets_file, 'r') as f:
                    data = json.load(f)
                self.presets = data.get("presets", [])
                self.presets_names = [p["name"] for p in self.presets]
            except Exception as e:
                print(f"Error loading presets: {e}")
        
        if not self.presets:
            self.presets = [
                {"name": "Pomodoro", "mode": "countdown", "work_minutes": 25, "short_break_minutes": 5, "long_break_minutes": 15, "long_break_interval": 4},
                {"name": "52/17 Rule", "mode": "countdown", "work_minutes": 52, "short_break_minutes": 17, "long_break_minutes": 17, "long_break_interval": 1},
                {"name": "90/20 Rule", "mode": "countdown", "work_minutes": 90, "short_break_minutes": 20, "long_break_minutes": 30, "long_break_interval": 2},
                {"name": "Animedoro", "mode": "countdown", "work_minutes": 50, "short_break_minutes": 20, "long_break_minutes": 20, "long_break_interval": 1},
                {"name": "Flowtime", "mode": "flowtime"}
            ]
            self.presets_names = [p["name"] for p in self.presets]

    def get_preset_details(self, name):
        for p in self.presets:
            if p["name"] == name:
                return p
        return {}
