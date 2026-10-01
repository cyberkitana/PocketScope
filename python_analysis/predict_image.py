from pathlib import Path
import json
import sys

import cv2
import joblib
import numpy as np
import pandas as pd
from ultralytics import YOLO


# =============================================================================
# PATHS
# =============================================================================

SCRIPT_DIR = Path(__file__).resolve().parent

DETECTOR_MODEL = (
    SCRIPT_DIR
    / "runs"
    / "detect"
    / "models"
    / "blood_cell_detector_fast"
    / "weights"
    / "best.pt"
)

CLASSIFIER_MODEL = (
    SCRIPT_DIR
    / "models"
    / "blood_cell_classifier_appearance.joblib"
)


# =============================================================================
# SETTINGS
# =============================================================================

YOLO_CONFIDENCE = 0.05
YOLO_IOU = 0.50

CROP_PADDING = 3
DUPLICATE_IOU = 0.50

MIN_ASPECT_RATIO = 1.80
MAX_SOLIDITY = 0.78
MAX_CIRCULARITY = 0.55
REQUIRED_SCORE = 0.85


# =============================================================================
# FEATURE EXTRACTION
# =============================================================================

def extract_features(image):
    rgb = cv2.cvtColor(
        image,
        cv2.COLOR_BGR2RGB,
    )

    red = rgb[:, :, 0]
    green = rgb[:, :, 1]
    blue = rgb[:, :, 2]

    gray = cv2.cvtColor(
        image,
        cv2.COLOR_BGR2GRAY,
    )

    features = {
        "red_mean": float(np.mean(red)),
        "red_std": float(np.std(red)),
        "green_mean": float(np.mean(green)),
        "green_std": float(np.std(green)),
        "blue_mean": float(np.mean(blue)),
        "blue_std": float(np.std(blue)),
        "gray_mean": float(np.mean(gray)),
        "gray_std": float(np.std(gray)),
    }

    edges = cv2.Canny(
        gray,
        50,
        150,
    )

    features["edge_density"] = (
        float(np.sum(edges > 0))
        / float(gray.size)
    )

    histogram = cv2.calcHist(
        [gray],
        [0],
        None,
        [8],
        [0, 256],
    ).flatten()

    histogram_total = np.sum(histogram)

    if histogram_total > 0:
        histogram = histogram / histogram_total

    for index, value in enumerate(histogram):
        features[f"gray_hist_{index}"] = float(value)

    return features


# =============================================================================
# IOU
# =============================================================================

def calculate_iou(box_a, box_b):
    ax1, ay1, ax2, ay2 = box_a
    bx1, by1, bx2, by2 = box_b

    intersection_x1 = max(ax1, bx1)
    intersection_y1 = max(ay1, by1)
    intersection_x2 = min(ax2, bx2)
    intersection_y2 = min(ay2, by2)

    intersection_width = max(
        0,
        intersection_x2 - intersection_x1,
    )

    intersection_height = max(
        0,
        intersection_y2 - intersection_y1,
    )

    intersection_area = (
        intersection_width
        * intersection_height
    )

    area_a = (
        max(0, ax2 - ax1)
        * max(0, ay2 - ay1)
    )

    area_b = (
        max(0, bx2 - bx1)
        * max(0, by2 - by1)
    )

    union_area = (
        area_a
        + area_b
        - intersection_area
    )

    if union_area <= 0:
        return 0.0

    return intersection_area / union_area


# =============================================================================
# RBC MORPHOLOGY
# =============================================================================

def analyse_rbc_morphology(crop):
    if crop.size == 0:
        return None

    gray = cv2.cvtColor(
        crop,
        cv2.COLOR_BGR2GRAY,
    )

    blurred = cv2.GaussianBlur(
        gray,
        (5, 5),
        0,
    )

    _, threshold = cv2.threshold(
        blurred,
        0,
        255,
        cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU,
    )

    kernel = np.ones(
        (3, 3),
        np.uint8,
    )

    threshold = cv2.morphologyEx(
        threshold,
        cv2.MORPH_OPEN,
        kernel,
    )

    threshold = cv2.morphologyEx(
        threshold,
        cv2.MORPH_CLOSE,
        kernel,
    )

    contours, _ = cv2.findContours(
        threshold,
        cv2.RETR_EXTERNAL,
        cv2.CHAIN_APPROX_SIMPLE,
    )

    if not contours:
        return None

    contour = max(
        contours,
        key=cv2.contourArea,
    )

    area = cv2.contourArea(contour)

    if area <= 0:
        return None

    x, y, width, height = cv2.boundingRect(
        contour
    )

    if height <= 0:
        return None

    aspect_ratio = width / height

    hull = cv2.convexHull(contour)
    hull_area = cv2.contourArea(hull)

    if hull_area > 0:
        solidity = area / hull_area
    else:
        solidity = 0.0

    perimeter = cv2.arcLength(
        contour,
        True,
    )

    if perimeter > 0:
        circularity = (
            4.0
            * np.pi
            * area
            / (perimeter * perimeter)
        )
    else:
        circularity = 0.0

    score = 0.0

    if aspect_ratio >= 2.30:
        score += 0.70
    elif aspect_ratio >= MIN_ASPECT_RATIO:
        score += 0.50

    if solidity < 0.65:
        score += 0.35
    elif solidity < MAX_SOLIDITY:
        score += 0.20

    if circularity < 0.40:
        score += 0.35
    elif circularity < MAX_CIRCULARITY:
        score += 0.20

    strong_elongation = (
        aspect_ratio >= MIN_ASPECT_RATIO
    )

    irregular_shape = (
        solidity < MAX_SOLIDITY
        or circularity < MAX_CIRCULARITY
    )

    sickle_like = (
        score >= REQUIRED_SCORE
        and strong_elongation
        and irregular_shape
    )

    return {
        "aspect_ratio": float(aspect_ratio),
        "solidity": float(solidity),
        "circularity": float(circularity),
        "score": float(score),
        "sickle_like": bool(sickle_like),
    }


# =============================================================================
# MAIN ANALYSIS
# =============================================================================

def analyse_image(
    image_path,
    requested_output_path=None,
):
    image_path = Path(image_path)

    if not image_path.exists():
        raise FileNotFoundError(
            f"Image does not exist: {image_path}"
        )

    image = cv2.imread(
        str(image_path)
    )

    if image is None:
        raise RuntimeError(
            f"Could not read image: {image_path}"
        )

    # -------------------------------------------------------------------------
    # CHECK MODEL FILES
    # -------------------------------------------------------------------------

    if not DETECTOR_MODEL.exists():
        raise FileNotFoundError(
            "YOLO detector model could not be found:\n"
            f"{DETECTOR_MODEL}"
        )

    if not CLASSIFIER_MODEL.exists():
        raise FileNotFoundError(
            "Blood cell classifier could not be found:\n"
            f"{CLASSIFIER_MODEL}"
        )

    # -------------------------------------------------------------------------
    # LOAD MODELS
    # -------------------------------------------------------------------------

    detector = YOLO(
        str(DETECTOR_MODEL)
    )

    classifier_package = joblib.load(
        CLASSIFIER_MODEL
    )

    classifier = classifier_package["model"]

    feature_columns = classifier_package[
        "feature_columns"
    ]

    # -------------------------------------------------------------------------
    # YOLO DETECTION
    # -------------------------------------------------------------------------

    results = detector(
        image,
        conf=YOLO_CONFIDENCE,
        iou=YOLO_IOU,
    )

    detections = []

    for result in results:
        for box in result.boxes:
            coordinates = (
                box.xyxy[0]
                .cpu()
                .numpy()
                .astype(int)
            )

            x1, y1, x2, y2 = coordinates

            x1 = max(0, x1)
            y1 = max(0, y1)

            x2 = min(
                image.shape[1],
                x2,
            )

            y2 = min(
                image.shape[0],
                y2,
            )

            if x2 <= x1 or y2 <= y1:
                continue

            confidence = float(
                box.conf[0]
            )

            detections.append(
                {
                    "box": [
                        int(x1),
                        int(y1),
                        int(x2),
                        int(y2),
                    ],
                    "confidence": confidence,
                }
            )

    detections.sort(
        key=lambda item: item["confidence"],
        reverse=True,
    )

    # -------------------------------------------------------------------------
    # REMOVE DUPLICATE DETECTIONS
    # -------------------------------------------------------------------------

    filtered_detections = []

    for detection in detections:
        duplicate = False

        for kept_detection in filtered_detections:
            overlap = calculate_iou(
                detection["box"],
                kept_detection["box"],
            )

            if overlap >= DUPLICATE_IOU:
                duplicate = True
                break

        if not duplicate:
            filtered_detections.append(
                detection
            )

    # -------------------------------------------------------------------------
    # INITIALISE RESULTS
    # -------------------------------------------------------------------------

    counts = {
        "WBC": 0,
        "RBC": 0,
        "Platelets": 0,
    }

    classified_image = image.copy()

    analysed_cells = []
    sickle_cells = []

    classification_confidences = []

    rbc_widths = []

    # -------------------------------------------------------------------------
    # CLASSIFY EACH DETECTION
    # -------------------------------------------------------------------------

    for detection_number, detection in enumerate(
        filtered_detections,
        start=1,
    ):
        x1, y1, x2, y2 = detection["box"]

        crop_x1 = max(
            0,
            x1 - CROP_PADDING,
        )

        crop_y1 = max(
            0,
            y1 - CROP_PADDING,
        )

        crop_x2 = min(
            image.shape[1],
            x2 + CROP_PADDING,
        )

        crop_y2 = min(
            image.shape[0],
            y2 + CROP_PADDING,
        )

        crop = image[
            crop_y1:crop_y2,
            crop_x1:crop_x2,
        ]

        if crop.size == 0:
            continue

        features = extract_features(
            crop
        )

        feature_dataframe = pd.DataFrame(
            [features]
        )

        try:
            feature_dataframe = (
                feature_dataframe[
                    feature_columns
                ]
            )
        except KeyError as error:
            raise RuntimeError(
                "The classifier expects feature columns "
                "that are missing from the extracted image features."
            ) from error

        prediction = classifier.predict(
            feature_dataframe
        )[0]

        probabilities = (
            classifier.predict_proba(
                feature_dataframe
            )[0]
        )

        probability_by_class = dict(
            zip(
                classifier.classes_,
                probabilities,
            )
        )

        confidence = float(
            probability_by_class[prediction]
        )

        classification_confidences.append(
            confidence
        )

        if prediction not in counts:
            counts[prediction] = 0

        counts[prediction] += 1

        morphology = None

        if prediction == "RBC":
            rbc_widths.append(
                x2 - x1
            )

            morphology = (
                analyse_rbc_morphology(
                    crop
                )
            )

            if (
                morphology is not None
                and morphology["sickle_like"]
            ):
                sickle_cells.append(
                    {
                        "number": detection_number,
                        "box": detection["box"],
                        "classification_confidence": confidence,
                        "morphology": morphology,
                    }
                )

        # ---------------------------------------------------------------------
        # BOX COLOURS
        # ---------------------------------------------------------------------

        if prediction == "WBC":
            box_colour = (
                0,
                255,
                255,
            )

        elif prediction == "Platelets":
            box_colour = (
                255,
                0,
                0,
            )

        else:
            box_colour = (
                0,
                255,
                0,
            )

        # ---------------------------------------------------------------------
        # DRAW DETECTION BOX
        # ---------------------------------------------------------------------

        cv2.rectangle(
            classified_image,
            (x1, y1),
            (x2, y2),
            box_colour,
            2,
        )

        cv2.putText(
            classified_image,
            f"#{detection_number}",
            (
                x1,
                min(
                    y2 + 15,
                    image.shape[0] - 5,
                ),
            ),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.45,
            (0, 255, 255),
            1,
        )

        cv2.putText(
            classified_image,
            f"{prediction} {confidence:.2f}",
            (
                x1,
                max(y1 - 5, 20),
            ),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.5,
            box_colour,
            2,
        )

        analysed_cells.append(
            {
                "number": detection_number,
                "class": prediction,
                "confidence": confidence,
                "box": detection["box"],
                "morphology": morphology,
            }
        )

    # -------------------------------------------------------------------------
    # HIGHLIGHT SICKLE-LIKE CELLS
    # -------------------------------------------------------------------------

    for sickle_cell in sickle_cells:
        x1, y1, x2, y2 = sickle_cell["box"]

        cv2.rectangle(
            classified_image,
            (x1, y1),
            (x2, y2),
            (0, 0, 255),
            4,
        )

        label = (
            f"#{sickle_cell['number']} "
            "SICKLE-LIKE"
        )

        cv2.putText(
            classified_image,
            label,
            (
                x1,
                max(y1 - 8, 20),
            ),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.55,
            (255, 255, 255),
            2,
            cv2.LINE_AA,
        )

    # -------------------------------------------------------------------------
    # CALCULATE SUMMARY VALUES
    # -------------------------------------------------------------------------

    total_cells = sum(
        counts.values()
    )

    if classification_confidences:
        overall_confidence = float(
            np.mean(
                classification_confidences
            )
        )
    else:
        overall_confidence = 0.0

    if rbc_widths:
        mean_rbc_diameter = float(
            np.mean(
                rbc_widths
            )
        )

        rbc_std = float(
            np.std(
                rbc_widths
            )
        )

        if mean_rbc_diameter > 0:
            size_variation = float(
                (
                    rbc_std
                    / mean_rbc_diameter
                )
                * 100
            )
        else:
            size_variation = 0.0

    else:
        mean_rbc_diameter = 0.0
        size_variation = 0.0

    # -------------------------------------------------------------------------
    # SCREENING INTERPRETATION
    # -------------------------------------------------------------------------

    if sickle_cells:
        screening_name = (
            "Sickle-like morphology flagged"
        )

        screening_motivation = (
            f"{len(sickle_cells)} RBC "
            "morphology finding(s) triggered "
            "the prototype screening rule. "
            "Further review is recommended."
        )

    elif total_cells == 0:
        screening_name = (
            "No cells detected"
        )

        screening_motivation = (
            "The computer analysis did not "
            "identify cells confidently enough "
            "for this image."
        )

    else:
        screening_name = (
            "No sickle-like morphology flagged"
        )

        screening_motivation = (
            f"{total_cells} cell(s) were assessed. "
            "No RBCs passed the prototype "
            "sickle-like morphology threshold."
        )

    if total_cells == 0:
        interpretation = (
            "No sufficiently confident cell "
            "detections were available for "
            "automated screening."
        )

    elif sickle_cells:
        interpretation = (
            "Prototype analysis identified RBC "
            "morphology that warrants further "
            "review. This screening result is "
            "not a diagnosis."
        )

    else:
        interpretation = (
            "Prototype analysis did not flag "
            "sickle-like RBC morphology in the "
            "assessed cells. Clinical review "
            "remains required."
        )

    # -------------------------------------------------------------------------
    # OUTPUT IMAGE
    # -------------------------------------------------------------------------

    if requested_output_path:
        output_path = Path(
            requested_output_path
        )
    else:
        output_path = (
            image_path.parent
            / f"{image_path.stem}_analysed.jpg"
        )

    output_path.parent.mkdir(
        parents=True,
        exist_ok=True,
    )

    saved = cv2.imwrite(
        str(output_path),
        classified_image,
    )

    if not saved:
        raise RuntimeError(
            f"Could not save analysed image: "
            f"{output_path}"
        )

    # -------------------------------------------------------------------------
    # RETURN JSON FOR FLUTTER
    # -------------------------------------------------------------------------

    return {
        "success": True,

        "input_image_path": str(
            image_path
        ),

        "annotated_image_path": str(
            output_path
        ),

        "screening_name": screening_name,

        "screening_status": (
            "review"
            if sickle_cells
            else "clear"
        ),

        "screening_motivation": (
            screening_motivation
        ),

        "prototype_only": True,

        "model_confidence": (
            overall_confidence
        ),

        "cells_assessed": (
            total_cells
        ),

        "mean_rbc_diameter_px": (
            mean_rbc_diameter
        ),

        "size_variation_percent": (
            size_variation
        ),

        "sickle_like_count": (
            len(sickle_cells)
        ),

        "counts": counts,

        "additional_findings": [
            f"{counts['WBC']} WBC",
            f"{counts['RBC']} RBC",
            f"{counts['Platelets']} platelets",
        ],

        "sickle_like_cells": (
            sickle_cells
        ),

        "detections": (
            analysed_cells
        ),

        "interpretation": (
            interpretation
        ),
    }


# =============================================================================
# COMMAND LINE ENTRY POINT
# =============================================================================

if __name__ == "__main__":
    try:
        if len(sys.argv) < 2:
            raise ValueError(
                "Usage: python predict_image.py "
                "<image_path> [output_path]"
            )

        image_path = sys.argv[1]

        output_path = None

        if len(sys.argv) >= 3:
            output_path = sys.argv[2]

        result = analyse_image(
            image_path,
            output_path,
        )

        print(
            json.dumps(
                result,
                separators=(",", ":"),
            )
        )

    except Exception as error:
        print(
            json.dumps(
                {
                    "success": False,
                    "error": str(error),
                }
            )
        )

        sys.exit(1)