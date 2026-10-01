from pathlib import Path

from ultralytics import YOLO


DATASET_CONFIG = Path("TXL-PBC/data.yaml")

MODEL_NAME = "yolo11n.pt"

OUTPUT_FOLDER = "models"


def main():
    print("=" * 60)
    print("FAST BLOOD CELL DETECTOR TRAINING")
    print("=" * 60)

    if not DATASET_CONFIG.exists():
        print()
        print(
            f"Dataset configuration not found: "
            f"{DATASET_CONFIG}"
        )
        return

    Path(OUTPUT_FOLDER).mkdir(
        parents=True,
        exist_ok=True,
    )

    model = YOLO(MODEL_NAME)

    print()
    print("Starting fast detector training...")
    print("Epochs: 5")
    print("Image size: 416")
    print()

    model.train(
        data=str(DATASET_CONFIG),
        epochs=5,
        imgsz=416,
        batch=8,
        project=OUTPUT_FOLDER,
        name="blood_cell_detector_fast",
        exist_ok=True,
    )

    print()
    print("=" * 60)
    print("FAST DETECTOR TRAINING COMPLETE")
    print("=" * 60)


if __name__ == "__main__":
    main()