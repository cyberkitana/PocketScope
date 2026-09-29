from pathlib import Path

import cv2
import numpy as np
import pandas as pd


# --------------------------------------------------
# Folders
# --------------------------------------------------

TRAIN_FOLDER = Path("training_cells")
VAL_FOLDER = Path("validation_cells")
TEST_FOLDER = Path("test_cells")

OUTPUT_FOLDER = Path("features")


# --------------------------------------------------
# Cell classes
# --------------------------------------------------

CLASS_NAMES = [
    "WBC",
    "RBC",
    "Platelets",
]


# --------------------------------------------------
# Feature extraction
# --------------------------------------------------

def extract_features(image_path):
    """
    Extract numerical image features from one cell crop.
    """

    image = cv2.imread(
        str(image_path)
    )

    if image is None:
        return None

    # OpenCV loads images as BGR.
    # Convert to RGB for colour measurements.
    rgb = cv2.cvtColor(
        image,
        cv2.COLOR_BGR2RGB,
    )

    height, width = image.shape[:2]

    # --------------------------------------------------
    # Colour features
    # --------------------------------------------------

    red = rgb[:, :, 0]
    green = rgb[:, :, 1]
    blue = rgb[:, :, 2]

    red_mean = float(np.mean(red))
    red_std = float(np.std(red))

    green_mean = float(np.mean(green))
    green_std = float(np.std(green))

    blue_mean = float(np.mean(blue))
    blue_std = float(np.std(blue))

    # --------------------------------------------------
    # Grayscale features
    # --------------------------------------------------

    gray = cv2.cvtColor(
        image,
        cv2.COLOR_BGR2GRAY,
    )

    gray_mean = float(np.mean(gray))
    gray_std = float(np.std(gray))

    # --------------------------------------------------
    # Shape / size features
    # --------------------------------------------------

    area = float(width * height)

    aspect_ratio = (
        float(width) / float(height)
        if height > 0
        else 0.0
    )

    # --------------------------------------------------
    # Edge features
    # --------------------------------------------------

    edges = cv2.Canny(
        gray,
        50,
        150,
    )

    edge_pixels = np.sum(
        edges > 0
    )

    total_pixels = edges.size

    edge_density = (
        float(edge_pixels)
        / float(total_pixels)
        if total_pixels > 0
        else 0.0
    )

    # --------------------------------------------------
    # Grayscale histogram
    # --------------------------------------------------

    histogram = cv2.calcHist(
        [gray],
        [0],
        None,
        [8],
        [0, 256],
    )

    histogram = histogram.flatten()

    histogram_total = np.sum(
        histogram
    )

    if histogram_total > 0:
        histogram = (
            histogram
            / histogram_total
        )

    # --------------------------------------------------
    # Build feature dictionary
    # --------------------------------------------------

    features = {
        "image": image_path.name,

        "red_mean": red_mean,
        "red_std": red_std,

        "green_mean": green_mean,
        "green_std": green_std,

        "blue_mean": blue_mean,
        "blue_std": blue_std,

        "gray_mean": gray_mean,
        "gray_std": gray_std,

        "width": width,
        "height": height,

        "area": area,
        "aspect_ratio": aspect_ratio,

        "edge_density": edge_density,
    }

    # Add histogram features.
    for index, value in enumerate(
        histogram
    ):
        features[
            f"gray_hist_{index}"
        ] = float(value)

    return features


# --------------------------------------------------
# Process one dataset split
# --------------------------------------------------

def process_split(
    split_name,
    input_folder,
):
    """
    Extract features from all cell crops
    in one dataset split.
    """

    print()
    print("=" * 40)
    print(
        f"{split_name.upper()} FEATURES"
    )
    print("=" * 40)

    rows = []

    for class_name in CLASS_NAMES:

        class_folder = (
            input_folder
            / class_name
        )

        if not class_folder.exists():
            print(
                f"Folder not found: "
                f"{class_folder}"
            )
            continue

        image_files = sorted(
            [
                file
                for file in class_folder.iterdir()
                if file.suffix.lower()
                in {
                    ".jpg",
                    ".jpeg",
                    ".png",
                }
            ]
        )

        print(
            f"{class_name}: "
            f"{len(image_files)} images"
        )

        for image_number, image_path in enumerate(
            image_files,
            start=1,
        ):

            feature_row = extract_features(
                image_path
            )

            if feature_row is None:
                print(
                    f"Could not read: "
                    f"{image_path.name}"
                )
                continue

            feature_row[
                "label"
            ] = class_name

            rows.append(
                feature_row
            )

    if not rows:
        print(
            "No features were extracted."
        )
        return

    dataframe = pd.DataFrame(
        rows
    )

    OUTPUT_FOLDER.mkdir(
        parents=True,
        exist_ok=True,
    )

    output_path = (
        OUTPUT_FOLDER
        / f"{split_name}_features.csv"
    )

    dataframe.to_csv(
        output_path,
        index=False,
    )

    print()
    print(
        f"Rows saved: "
        f"{len(dataframe)}"
    )

    print(
        f"Output: "
        f"{output_path}"
    )


# --------------------------------------------------
# Main
# --------------------------------------------------

def main():

    process_split(
        "train",
        TRAIN_FOLDER,
    )

    process_split(
        "val",
        VAL_FOLDER,
    )

    process_split(
        "test",
        TEST_FOLDER,
    )

    print()
    print(
        "Feature extraction complete."
    )


if __name__ == "__main__":
    main()