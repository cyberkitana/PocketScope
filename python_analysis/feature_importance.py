from pathlib import Path

import joblib
import pandas as pd


MODEL_FILE = Path(
    "models/blood_cell_classifier.joblib"
)

TRAIN_FILE = Path(
    "features/train_features.csv"
)


def main():
    print("Loading model...")

    model_package = joblib.load(
        MODEL_FILE
    )

    model = model_package["model"]
    feature_columns = model_package[
        "feature_columns"
    ]

    print("Model loaded.")

    importance = pd.DataFrame(
        {
            "feature": feature_columns,
            "importance": model.feature_importances_,
        }
    )

    importance = importance.sort_values(
        by="importance",
        ascending=False,
    )

    print()
    print("=" * 60)
    print("FEATURE IMPORTANCE")
    print("=" * 60)

    for _, row in importance.iterrows():
        print(
            f"{row['feature']:<25} "
            f"{row['importance']:.4f}"
        )

    print()
    print(
        "Feature importance check complete."
    )


if __name__ == "__main__":
    main()