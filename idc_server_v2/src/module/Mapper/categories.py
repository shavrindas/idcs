class et_category:
    bool_logs = "bool"
    real_logs = "real"
    real_static_logs = "real_static"

class DataFormat:
    def __init__(self):
        self.vals = []
        self.val_sum = 0.0
        self.val_min = float('inf')
        self.val_max = float('-inf')
        self.val_mean = 0.0
        self.val_var = 0.0
        self.val_std = 0.0
        self.count: int = 0

    def to_dict(self, is_bool=False):
        """JSON 변환용 딕셔너리 생성"""
        if is_bool:
            return {
                "last_value": self.vals[-1] if self.vals else None
            }
        else:
            return {
                "val_mean": getattr(self, 'val_mean', 0.0),
                "val_var": getattr(self, 'val_var', 0.0),
                "val_std": getattr(self, 'val_std', 0.0),
                "val_max": None if self.val_max == float('-inf') else self.val_max,
                "val_min": None if self.val_min == float('inf') else self.val_min,
                "count": self.count
            }
