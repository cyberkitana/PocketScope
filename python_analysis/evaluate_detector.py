from pathlib import Path

from ultralytics import YOLO


SCRIPT_DIR = Path(__file__).resolve().parent

MODEL_FILE = (
    SCRIPT_DIR
    / "models"
    / "best.pt"
)

DATASET_CONFIG = (
    SCRIPT_DIR
    / "TXL-PBC"
    / "data.yaml"
)

def main():
    print("=" * 60)
    print("BLOOD CELL DETECTOR EVALUATION")
    print("=" * 60)

    if not MODEL_FILE.exists():
        print()
        print(
            f"Model not found: {MODEL_FILE}"
        )
        return

    model = YOLO(
        str(MODEL_FILE)
    )

    print()
    print("Evaluating on the test dataset...")
    print()

    results = model.val(
        data=str(DATASET_CONFIG.resolve()),
        split="test",
        imgsz=416,
        batch=8,
        verbose=True,
    )

    print()
    print("=" * 60)
    print("TEST RESULTS")
    print("=" * 60)

    print()
    print(
        f"Box mAP50: "
        f"{results.box.map50:.4f}"
    )

    print(
        f"Box mAP50-95: "
        f"{results.box.map:.4f}"
    )

    print()
    print(
        "Detector evaluation complete."
    )


if __name__ == "__main__":
    main()