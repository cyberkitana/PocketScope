from pathlib import Path

from image_processing import (
    load_image,
    get_image_dimensions,
)


DATASET_FOLDER = Path("TXL-PBC/images/train")


def main():
    image_files = [
        file
        for file in DATASET_FOLDER.iterdir()
        if file.suffix.lower() in {
            ".jpg",
            ".jpeg",
            ".png",
        }
    ]

    print(
        f"Training images found: {len(image_files)}"
    )

    if not image_files:
        print(
            "No training images were found."
        )
        return

    first_image = image_files[0]

    image = load_image(
        str(first_image)
    )

    width, height = get_image_dimensions(
        image
    )

    print(
        f"Example image: {first_image.name}"
    )

    print(
        f"Image dimensions: {width} x {height}"
    )


if __name__ == "__main__":
    main()