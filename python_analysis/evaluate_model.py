from pathlib import Path

import joblib
import pandas as pd

from sklearn.metrics import (
    accuracy_score,
    classification_report,
    confusion_matrix,
)


# --------------------------------------------------
# Files
# --------------------------------------------------

MODEL_FILE = Path(
    "models/blood_cell_classifier_appearance.joblib"
)

VAL_FILE = Path(
    "features/val_features.csv"
)

TEST_FILE = Path(
    "features/test_features.csv"
)


# --------------------------------------------------
# Load model
# --------------------------------------------------

def load_model():
    """
    Load the appearance-only Random Forest.
    """

    model_package = joblib.load(
        MODEL_FILE
    )

    model = model_package["model"]

    feature_columns = (
        model_package[
            "feature_columns"
        ]
    )

    return model, feature_columns


# --------------------------------------------------
# Load dataset
# --------------------------------------------------

def load_dataset(
    dataset_file,
):
    """
    Load a feature dataset.
    """

    return pd.read_csv(
        dataset_file
    )


# --------------------------------------------------
# Evaluate
# --------------------------------------------------

def evaluate_dataset(
    model,
    feature_columns,
    dataframe,
    dataset_name,
):
    """
    Evaluate the classifier on one dataset.
    """

    X = dataframe[
        feature_columns
    ]

    y = dataframe["label"]

    predictions = model.predict(
        X
    )

    accuracy = accuracy_score(
        y,
        predictions,
    )

    print()
    print("=" * 60)
    print(
        f"{dataset_name.upper()} RESULTS"
    )
    print("=" * 60)

    print()
    print(
        f"Accuracy: {accuracy:.4f}"
    )

    print()
    print(
        "Classification report:"
    )

    print(
        classification_report(
            y,
            predictions,
            labels=[
                "WBC",
                "RBC",
                "Platelets",
            ],
            zero_division=0,
        )
    )

    print(
        "Confusion matrix:"
    )

    matrix = confusion_matrix(
        y,
        predictions,
        labels=[
            "WBC",
            "RBC",
            "Platelets",
        ],
    )

    print(matrix)


# --------------------------------------------------
# Main
# --------------------------------------------------

def main():

    model, feature_columns = (
        load_model()
    )

    print(
        "Appearance-only model loaded successfully."
    )

    print()
    print(
        f"Number of features: "
        f"{len(feature_columns)}"
    )

    print()
    print(
        "Features being used:"
    )

    for feature in feature_columns:
        print(
            f"  - {feature}"
        )

    # ----------------------------------------------
    # Validation
    # ----------------------------------------------

    validation_data = load_dataset(
        VAL_FILE
    )

    evaluate_dataset(
        model,
        feature_columns,
        validation_data,
        "Validation",
    )

    # ----------------------------------------------
    # Test
    # ----------------------------------------------

    test_data = load_dataset(
        TEST_FILE
    )

    evaluate_dataset(
        model,
        feature_columns,
        test_data,
        "Test",
    )

    print()
    print(
        "Appearance-only evaluation complete."
    )


if __name__ == "__main__":
    main()