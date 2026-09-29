from pathlib import Path


TRAINING_FOLDER = Path("training_cells")

CLASS_NAMES = [
    "WBC",
    "RBC",
    "Platelets",
]


def main():
    print("Training cell distribution")
    print("=" * 30)

    total = 0

    for class_name in CLASS_NAMES:

        class_folder = (
            TRAINING_FOLDER
            / class_name
        )

        count = len(
            [
                file
                for file in class_folder.iterdir()
                if file.is_file()
            ]
        )

        print(
            f"{class_name}: {count}"
        )

        total += count

    print("=" * 30)

    print(
        f"Total: {total}"
    )


if __name__ == "__main__":
    main()