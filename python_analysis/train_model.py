from pathlib import Path

import joblib
import pandas as pd

from sklearn.ensemble import RandomForestClassifier


# --------------------------------------------------
# Files
# --------------------------------------------------

TRAIN_FILE = Path(
    "features/train_features.csv"
)

MODEL_FOLDER = Path("models")

MODEL_FILE = (
    MODEL_FOLDER
    / "blood_cell_classifier_appearance.joblib"
)


# --------------------------------------------------
# Features we do NOT want to use
# --------------------------------------------------

EXCLUDED_FEATURES = {
    "image",
    "label",
    "width",
    "height",
    "area",
    "aspect_ratio",
}


# --------------------------------------------------
# Load training data
# --------------------------------------------------

def load_training_data():
    """
    Load the training feature dataset.
    """

    dataframe = pd.read_csv(
        TRAIN_FILE
    )

    print(
        f"Training rows: {len(dataframe)}"
    )

    return dataframe


# --------------------------------------------------
# Prepare features
# --------------------------------------------------

def prepare_features(dataframe):
    """
    Separate the image label from the numerical
    appearance features used by the classifier.
    """

    feature_columns = [
        column
        for column in dataframe.columns
        if column not in EXCLUDED_FEATURES
    ]

    X = dataframe[
        feature_columns
    ]

    y = dataframe["label"]

    return X, y, feature_columns


# --------------------------------------------------
# Train model
# --------------------------------------------------

def train_model(X, y):
    """
    Train an appearance-based Random Forest.

    Class weighting compensates for the unequal
    number of examples in each cell class.
    """

    model = RandomForestClassifier(
        n_estimators=300,
        class_weight="balanced",
        random_state=42,
        n_jobs=-1,
    )

    print()
    print(
        "Training appearance-only Random Forest..."
    )

    model.fit(
        X,
        y,
    )

    print(
        "Training complete."
    )

    return model


# --------------------------------------------------
# Save model
# --------------------------------------------------

def save_model(
    model,
    feature_columns,
):
    """
    Save the model and feature-column order.
    """

    MODEL_FOLDER.mkdir(
        parents=True,
        exist_ok=True,
    )

    model_package = {
        "model": model,
        "feature_columns": feature_columns,
    }

    joblib.dump(
        model_package,
        MODEL_FILE,
    )

    print()
    print(
        f"Model saved to: "
        f"{MODEL_FILE}"
    )


# --------------------------------------------------
# Main
# --------------------------------------------------

def main():

    dataframe = load_training_data()

    X, y, feature_columns = (
        prepare_features(
            dataframe
        )
    )

    print()
    print(
        f"Appearance features used: "
        f"{len(feature_columns)}"
    )

    print()
    print(
        "Excluded features:"
    )

    for feature in sorted(
        EXCLUDED_FEATURES
    ):
        print(
            f"  - {feature}"
        )

    print()
    print(
        "Training class distribution:"
    )

    print(
        y.value_counts()
    )

    model = train_model(
        X,
        y,
    )

    save_model(
        model,
        feature_columns,
    )

    print()
    print(
        "Appearance-only model training complete."
    )


if __name__ == "__main__":
    main()