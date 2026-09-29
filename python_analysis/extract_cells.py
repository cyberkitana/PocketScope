from pathlib import Path

import cv2


# TXL-PBC dataset
DATASET_FOLDER = Path("TXL-PBC")

# Output folders
TRAIN_OUTPUT = Path("training_cells")
VAL_OUTPUT = Path("validation_cells")
TEST_OUTPUT = Path("test_cells")


# TXL-PBC class mapping
CLASS_NAMES = {
    0: "WBC",
    1: "RBC",
    2: "Platelets",
}


def load_image(image_path):
    """
    Load an image from the supplied path.
    """

    image = cv2.imread(
        str(image_path)
    )

    if image is None:
        raise FileNotFoundError(
            f"Could not load image: {image_path}"
        )

    return image


def convert_yolo_box_to_pixels(
    image_width,
    image_height,
    center_x,
    center_y,
    box_width,
    box_height,
):
    """
    Convert a YOLO-format bounding box
    into pixel coordinates.
    """

    center_x_pixels = (
        center_x * image_width
    )

    center_y_pixels = (
        center_y * image_height
    )

    box_width_pixels = (
        box_width * image_width
    )

    box_height_pixels = (
        box_height * image_height
    )

    x1 = int(
        center_x_pixels
        - (box_width_pixels / 2)
    )

    y1 = int(
        center_y_pixels
        - (box_height_pixels / 2)
    )

    x2 = int(
        center_x_pixels
        + (box_width_pixels / 2)
    )

    y2 = int(
        center_y_pixels
        + (box_height_pixels / 2)
    )

    return x1, y1, x2, y2


def box_touches_image_boundary(
    box,
    image_width,
    image_height,
):
    """
    Check whether a bounding box touches
    the edge of the original image.

    Edge-touching cells may be partially visible,
    so they are excluded from the classifier dataset.
    """

    x1, y1, x2, y2 = box

    return (
        x1 <= 0
        or y1 <= 0
        or x2 >= image_width
        or y2 >= image_height
    )


def crop_cell(
    image,
    box,
    padding=3,
):
    """
    Crop one labelled cell from an image.
    """

    x1, y1, x2, y2 = box

    image_height, image_width = (
        image.shape[:2]
    )

    x1 = max(
        0,
        x1 - padding,
    )

    y1 = max(
        0,
        y1 - padding,
    )

    x2 = min(
        image_width,
        x2 + padding,
    )

    y2 = min(
        image_height,
        y2 + padding,
    )

    if x2 <= x1 or y2 <= y1:
        return None

    return image[
        y1:y2,
        x1:x2
    ]


def process_image(
    image_path,
    labels_folder,
    output_folder,
):
    """
    Extract labelled cells from one image.
    """

    label_path = (
        labels_folder
        / f"{image_path.stem}.txt"
    )

    if not label_path.exists():
        print(
            f"No label file found for "
            f"{image_path.name}"
        )

        return {
            "WBC": 0,
            "RBC": 0,
            "Platelets": 0,
        }

    image = load_image(
        image_path
    )

    image_height, image_width = (
        image.shape[:2]
    )

    extracted_counts = {
        "WBC": 0,
        "RBC": 0,
        "Platelets": 0,
    }

    with open(
        label_path,
        "r",
        encoding="utf-8",
    ) as label_file:

        for line in label_file:

            line = line.strip()

            if not line:
                continue

            values = line.split()

            if len(values) != 5:
                continue

            class_id = int(
                values[0]
            )

            if class_id not in CLASS_NAMES:
                continue

            center_x = float(
                values[1]
            )

            center_y = float(
                values[2]
            )

            box_width = float(
                values[3]
            )

            box_height = float(
                values[4]
            )

            class_name = CLASS_NAMES[
                class_id
            ]

            box = (
                convert_yolo_box_to_pixels(
                    image_width,
                    image_height,
                    center_x,
                    center_y,
                    box_width,
                    box_height,
                )
            )

            # Skip cells that are partially outside
            # the original image.
            if box_touches_image_boundary(
                box,
                image_width,
                image_height,
            ):
                continue

            cell_image = crop_cell(
                image,
                box,
            )

            if cell_image is None:
                continue

            class_folder = (
                output_folder
                / class_name
            )

            class_folder.mkdir(
                parents=True,
                exist_ok=True,
            )

            cell_number = (
                extracted_counts[class_name]
                + 1
            )

            output_filename = (
                f"{image_path.stem}"
                f"_cell_{cell_number:04d}.jpg"
            )

            output_path = (
                class_folder
                / output_filename
            )

            cv2.imwrite(
                str(output_path),
                cell_image,
            )

            extracted_counts[
                class_name
            ] += 1

    return extracted_counts


def process_split(
    split_name,
    output_folder,
):
    """
    Process one TXL-PBC dataset split.
    """

    images_folder = (
        DATASET_FOLDER
        / "images"
        / split_name
    )

    labels_folder = (
        DATASET_FOLDER
        / "labels"
        / split_name
    )

    image_files = sorted(
        [
            file
            for file in images_folder.iterdir()
            if file.suffix.lower()
            in {
                ".jpg",
                ".jpeg",
                ".png",
            }
        ]
    )

    print()
    print(
        f"{split_name.upper()} SET"
    )
    print(
        "=" * 30
    )

    print(
        f"Images found: "
        f"{len(image_files)}"
    )

    total_counts = {
        "WBC": 0,
        "RBC": 0,
        "Platelets": 0,
    }

    for image_number, image_path in enumerate(
        image_files,
        start=1,
    ):

        print(
            f"Processing "
            f"{image_number}/{len(image_files)}: "
            f"{image_path.name}"
        )

        counts = process_image(
            image_path,
            labels_folder,
            output_folder,
        )

        for class_name in total_counts:
            total_counts[class_name] += (
                counts[class_name]
            )

    print()
    print(
        f"{split_name.upper()} CELLS"
    )

    print(
        f"WBC: "
        f"{total_counts['WBC']}"
    )

    print(
        f"RBC: "
        f"{total_counts['RBC']}"
    )

    print(
        f"Platelets: "
        f"{total_counts['Platelets']}"
    )

    print(
        f"Total: "
        f"{sum(total_counts.values())}"
    )


def main():
    """
    Extract clean labelled cells from
    the train, validation and test sets.
    """

    process_split(
        "train",
        TRAIN_OUTPUT,
    )

    process_split(
        "val",
        VAL_OUTPUT,
    )

    process_split(
        "test",
        TEST_OUTPUT,
    )

    print()
    print(
        "Cell extraction complete."
    )


if __name__ == "__main__":
    main()