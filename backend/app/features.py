import io
import numpy as np
from PIL import Image
from skimage.feature import hog
from skimage.transform import resize


def extract_hog(image_bytes: bytes) -> np.ndarray:
    """تحويل صورة الخط إلى بصمة رقمية (متجه HOG)."""
    img = Image.open(io.BytesIO(image_bytes)).convert("L")
    arr = np.array(img)
    arr = resize(arr, (128, 512), anti_aliasing=True)
    fd = hog(arr, orientations=9, pixels_per_cell=(16, 16), cells_per_block=(2, 2),
             block_norm="L2-Hys", transform_sqrt=True, feature_vector=True)
    return fd
