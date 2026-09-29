from pathlib import Path

import cv2


# --------------------------------------------------
# Dataset folders
# --------------------------------------------------

DATASET_FOLDER = Path("TXL-PBC")

IMAGES_FOLDER = (
    DATASET_FOLDER
    / "images"
    / "test"
)

LABELS_FOLDER = (
    DATASET_FOLDER
    / "labels"
    / "test"
)

OUTPUT_FOLDER = Path(
    "detection_diagnostics"
)


# --------------------------------------------------
# Detection settings
# --------------------------------------------------

MIN_AREA = 150
MAX_AREA = 30000

MIN_WIDTH = 8
MIN_HEIGHT = 8

MATCH_IOU = 0.30


# --------------------------------------------------
# Convert YOLO annotation to pixel box
# --------------------------------------------------

def yolo_to_box(
    image_width,
    image_height,
    values,
):
    """
    Convert a YOLO annotation into
    x1, y1, x2, y2 pixel coordinates.
    """

    center_x = float(values[1])
    center_y = float(values[2])
    box_width = float(values[3])
    box_height = float(values[4])

    center_x *= image_width
    center_y *= image_height

    box_width *= image_width
    box_height *= image_height

    x1 = int(
        center_x
        - box_width / 2
    )

    y1 = int(
        center_y
        - box_height / 2
    )

    x2 = int(
        center_x
        + box_width / 2
    )

    y2 = int(
        center_y
        + box_height / 2
    )

    return (
        x1,
        y1,
        x2,
        y2,
    )


# --------------------------------------------------
# Load ground-truth boxes
# --------------------------------------------------

def load_ground_truth(
    label_path,
    image_width,
    image_height,
):
    """
    Load labelled cell boxes from one image.
    """

    boxes = []

    if not label_path.exists():
        return boxes

    with open(
        label_path,
        "r",
        encoding="utf-8",
    ) as label_file:

        for line in label_file:

            values = line.strip().split()

            if len(values) != 5:
                continue

            class_id = int(
                values[0]
            )

            box = yolo_to_box(
                image_width,
                image_height,
                values,
            )

            x1, y1, x2, y2 = box

            if (
                x1 <= 0
                or y1 <= 0
                or x2 >= image_width
                or y2 >= image_height
            ):
                continue

            boxes.append(
                {
                    "class_id": class_id,
                    "box": box,
                }
            )

    return boxes


# --------------------------------------------------
# Candidate generation
# --------------------------------------------------

def generate_candidates(image):
    """
    Generate cell candidates using classical
    image processing.
    """

    gray = cv2.cvtColor(
        image,
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
        cv2.THRESH_BINARY_INV
        + cv2.THRESH_OTSU,
    )

    kernel = cv2.getStructuringElement(
        cv2.MORPH_ELLIPSE,
        (3, 3),
    )

    cleaned = cv2.morphologyEx(
        threshold,
        cv2.MORPH_OPEN,
        kernel,
        iterations=1,
    )

    cleaned = cv2.morphologyEx(
        cleaned,
        cv2.MORPH_CLOSE,
        kernel,
        iterations=2,
    )

    contours, _ = cv2.findContours(
        cleaned,
        cv2.RETR_EXTERNAL,
        cv2.CHAIN_APPROX_SIMPLE,
    )

    candidates = []

    for contour in contours:

        area = cv2.contourArea(
            contour
        )

        if area < MIN_AREA:
            continue

        if area > MAX_AREA:
            continue

        x, y, width, height = (
            cv2.boundingRect(contour)
        )

        if width < MIN_WIDTH:
            continue

        if height < MIN_HEIGHT:
            continue

        candidates.append(
            (
                x,
                y,
                x + width,
                y + height,
            )
        )

    return candidates


# --------------------------------------------------
# IoU
# --------------------------------------------------

def calculate_iou(
    box_a,
    box_b,
):
    """
    Calculate Intersection over Union.
    """

    ax1, ay1, ax2, ay2 = box_a
    bx1, by1, bx2, by2 = box_b

    intersection_x1 = max(
        ax1,
        bx1,
    )

    intersection_y1 = max(
        ay1,
        by1,
    )

    intersection_x2 = min(
        ax2,
        bx2,
    )

    intersection_y2 = min(
        ay2,
        by2,
    )

    intersection_width = max(
        0,
        intersection_x2
        - intersection_x1,
    )

    intersection_height = max(
        0,
        intersection_y2
        - intersection_y1,
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

    return (
        intersection_area
        / union_area
    )


# --------------------------------------------------
# Find best candidate for each true cell
# --------------------------------------------------

def find_matches(
    candidates,
    ground_truth,
):
    """
    Find the best candidate for each ground-truth
    cell and determine whether it was detected.
    """

    matches = []

    for true_cell in ground_truth:

        true_box = true_cell["box"]

        best_candidate = None
        best_iou = 0.0

        for candidate in candidates:

            iou = calculate_iou(
                true_box,
                candidate,
            )

            if iou > best_iou:
                best_iou = iou
                best_candidate = candidate

        matches.append(
            {
                "true_box": true_box,
                "class_id": true_cell[
                    "class_id"
                ],
                "candidate": best_candidate,
                "iou": best_iou,
                "matched": (
                    best_iou >= MATCH_IOU
                ),
            }
        )

    return matches


# --------------------------------------------------
# Save diagnostic image
# --------------------------------------------------

def save_diagnostic(
    image,
    candidates,
    matches,
    image_name,
):
    """
    Save a diagnostic image.

    Green = detected ground-truth cell
    Yellow = missed ground-truth cell
    Red = generated candidate
    """

    output = image.copy()

    matched_candidates = set()

    # ----------------------------------------------
    # Draw ground-truth cells
    # ----------------------------------------------

    for match in matches:

        x1, y1, x2, y2 = (
            match["true_box"]
        )

        if match["matched"]:

            # Green: detected cell.
            cv2.rectangle(
                output,
                (x1, y1),
                (x2, y2),
                (0, 255, 0),
                2,
            )

            candidate = match[
                "candidate"
            ]

            if candidate is not None:
                matched_candidates.add(
                    candidate
                )

        else:

            # Yellow: missed cell.
            cv2.rectangle(
                output,
                (x1, y1),
                (x2, y2),
                (0, 255, 255),
                3,
            )

    # ----------------------------------------------
    # Draw candidate boxes
    # ----------------------------------------------

    for candidate in candidates:

        x1, y1, x2, y2 = candidate

        if candidate in matched_candidates:
            continue

        # Red: candidate that did not provide
        # a successful match.
        cv2.rectangle(
            output,
            (x1, y1),
            (x2, y2),
            (0, 0, 255),
            1,
        )

    OUTPUT_FOLDER.mkdir(
        parents=True,
        exist_ok=True,
    )

    output_path = (
        OUTPUT_FOLDER
        / image_name
    )

    cv2.imwrite(
        str(output_path),
        output,
    )


# --------------------------------------------------
# Process one image
# --------------------------------------------------

def process_image(
    image_path,
    save_visual=False,
):
    """
    Process one smear image.
    """

    image = cv2.imread(
        str(image_path)
    )

    if image is None:
        return None

    image_height, image_width = (
        image.shape[:2]
    )

    label_path = (
        LABELS_FOLDER
        / f"{image_path.stem}.txt"
    )

    ground_truth = (
        load_ground_truth(
            label_path,
            image_width,
            image_height,
        )
    )

    candidates = (
        generate_candidates(
            image
        )
    )

    matches = find_matches(
        candidates,
        ground_truth,
    )

    matched_count = sum(
        match["matched"]
        for match in matches
    )

    if save_visual:
        save_diagnostic(
            image,
            candidates,
            matches,
            image_path.name,
        )

    return {
        "ground_truth": len(
            ground_truth
        ),
        "candidates": len(
            candidates
        ),
        "matched": matched_count,
    }


# --------------------------------------------------
# Main
# --------------------------------------------------

def main():

    image_files = sorted(
        [
            file
            for file in IMAGES_FOLDER.iterdir()
            if file.suffix.lower()
            in {
                ".jpg",
                ".jpeg",
                ".png",
            }
        ]
    )

    print(
        f"Test images found: "
        f"{len(image_files)}"
    )

    total_ground_truth = 0
    total_candidates = 0
    total_matched = 0

    for index, image_path in enumerate(
        image_files,
        start=1,
    ):

        print(
            f"Processing "
            f"{index}/{len(image_files)}: "
            f"{image_path.name}"
        )

        result = process_image(
            image_path,
            save_visual=index <= 3,
        )

        if result is None:
            continue

        total_ground_truth += (
            result["ground_truth"]
        )

        total_candidates += (
            result["candidates"]
        )

        total_matched += (
            result["matched"]
        )

    print()
    print("=" * 60)
    print(
        "CANDIDATE DETECTION RESULTS"
    )
    print("=" * 60)

    print()
    print(
        f"Ground-truth cells: "
        f"{total_ground_truth}"
    )

    print(
        f"Candidate boxes: "
        f"{total_candidates}"
    )

    print()
    print(
        f"Cells detected at IoU >= "
        f"{MATCH_IOU:.2f}: "
        f"{total_matched}"
    )

    if total_ground_truth > 0:

        recall = (
            total_matched
            / total_ground_truth
        )

        print()
        print(
            f"Detection recall @ IoU "
            f"{MATCH_IOU:.2f}: "
            f"{recall:.4f}"
        )

    print()
    print(
        "Diagnostic images saved to:"
    )

    print(
        OUTPUT_FOLDER
    )

    print()
    print(
        "Candidate detection evaluation complete."
    )


if __name__ == "__main__":
    main()