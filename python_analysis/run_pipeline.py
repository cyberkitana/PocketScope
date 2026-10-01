from pathlib import Path

import cv2
import joblib
import numpy as np
from ultralytics import YOLO


# -----------------------------
# Files
# -----------------------------

SCRIPT_DIR = Path(__file__).resolve().parent

DETECTOR_MODEL = (
    SCRIPT_DIR
    / "models"
    / "best.pt"
)

CLASSIFIER_MODEL = (
    SCRIPT_DIR
    / "models"
    / "blood_cell_classifier_appearance.joblib"
)

IMAGE_FILE = (
    SCRIPT_DIR
    / "test_cells"
    / "WBC"
    / "66151af4d9d05e9e940a47e4ce1e45cf_cell_0002.jpg"
)

OUTPUT_FILE = (
    SCRIPT_DIR
    / "pipeline_result.jpg"
)

# -----------------------------
# Load models
# -----------------------------

detector = YOLO(
    DETECTOR_MODEL
)

classifier_package = joblib.load(
    CLASSIFIER_MODEL
)

classifier = classifier_package["model"]

feature_columns = classifier_package[
    "feature_columns"
]


# -----------------------------
# Feature extraction
# -----------------------------

def extract_features(image):

    rgb = cv2.cvtColor(
        image,
        cv2.COLOR_BGR2RGB
    )

    red = rgb[:, :, 0]
    green = rgb[:, :, 1]
    blue = rgb[:, :, 2]

    gray = cv2.cvtColor(
        image,
        cv2.COLOR_BGR2GRAY
    )

    height, width = image.shape[:2]

    features = {

        "red_mean": np.mean(red),
        "red_std": np.std(red),

        "green_mean": np.mean(green),
        "green_std": np.std(green),

        "blue_mean": np.mean(blue),
        "blue_std": np.std(blue),

        "gray_mean": np.mean(gray),
        "gray_std": np.std(gray),

        "edge_density":
            np.sum(
                cv2.Canny(gray,50,150) > 0
            )
            /
            gray.size,

    }


    hist = cv2.calcHist(
        [gray],
        [0],
        None,
        [8],
        [0,256]
    ).flatten()


    hist = hist / hist.sum()


    for i,value in enumerate(hist):
        features[f"gray_hist_{i}"] = value


    return features


# -----------------------------
# Run pipeline
# -----------------------------

image = cv2.imread(
    str(IMAGE_FILE)
)

if image is None:
    raise Exception(
        "Image not found"
    )


results = detector(
    image
)


for result in results:

    boxes = result.boxes.xyxy.cpu().numpy()

    for box in boxes:

        x1,y1,x2,y2 = map(
            int,
            box
        )

        crop = image[
            y1:y2,
            x1:x2
        ]

        if crop.size == 0:
            continue


        features = extract_features(
            crop
        )


        dataframe = [
            features[col]
            for col in feature_columns
        ]


        prediction = classifier.predict(
            [dataframe]
        )[0]


        cv2.rectangle(
            image,
            (x1,y1),
            (x2,y2),
            (0,255,0),
            2
        )


        cv2.putText(
            image,
            prediction,
            (x1,y1-5),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.6,
            (0,255,0),
            2
        )


cv2.imwrite(
    str(OUTPUT_FILE),
    image
)


print(
    "Pipeline complete:"
)

print(
    OUTPUT_FILE
)