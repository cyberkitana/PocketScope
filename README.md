# PocketScope

PocketScope is a mobile prototype for portable biological sample screening. It combines a Flutter application with a Python-based image analysis pipeline to support image-based screening of blood and urine samples.

The project is designed around situations where access to conventional laboratory equipment and infrastructure may be limited. It explores how smartphone imaging and automated image analysis could support preliminary screening workflows.

## Features

* Patient registration and patient records
* Sample registration and tracking
* Image capture and image review
* Blood smear image analysis
* Automated blood cell detection
* Blood cell classification
* Preliminary screening result display
* Clinical report generation
* Local data storage
* User login and account creation

## Image Analysis

The Python analysis component uses computer vision and machine learning to process microscopy images.

The current pipeline includes:

1. Image input
2. Blood cell detection using YOLO
3. Cell cropping and feature extraction
4. Blood cell classification using trained machine learning models
5. Analysis results returned to the Flutter application

The project includes trained model files required by the analysis pipeline.

## Technologies

### Mobile application

* Flutter
* Dart
* SQLite
* Flutter plugins for image handling and local storage

### Image analysis

* Python
* OpenCV
* NumPy
* Pillow
* pandas
* scikit-learn
* joblib
* Ultralytics YOLO

## Project Structure

```text
pocketscope/
├── assets/
│   ├── fonts/
│   └── images/
├── lib/
│   ├── app/
│   ├── screens/
│   ├── services/
│   └── utils/
├── python_analysis/
│   ├── models/
│   ├── analysis_server.py
│   ├── evaluate_detector.py
│   ├── evaluate_model.py
│   ├── feature_importance.py
│   ├── predict_image.py
│   ├── run_pipeline.py
│   ├── train_detector.py
│   ├── train_model.py
│   ├── requirements.txt
│   └── yolo11n.pt
├── test/
├── .gitignore
├── pubspec.yaml
└── README.md
```

## Setup

### Flutter

Install Flutter and the required platform development tools.

From the project directory:

```bash
flutter pub get
flutter run
```

### Python

The Python analysis environment uses Python 3 and a virtual environment.

From the `python_analysis` directory:

```bash
python -m venv .venv
```

Activate the virtual environment on Windows:

```cmd
.venv\Scripts\activate
```

Install the required packages:

```cmd
pip install -r requirements.txt
```

The Python analysis scripts are located in:

```text
python_analysis/
```

## Models

The repository contains the trained model files used by the current analysis pipeline:

```text
python_analysis/models/best.pt
python_analysis/models/blood_cell_classifier.joblib
python_analysis/models/blood_cell_classifier_appearance.joblib
python_analysis/yolo11n.pt
```

The training datasets and generated training outputs are excluded from the repository through `.gitignore`.

## Dataset

The project uses image datasets for developing and evaluating the image analysis pipeline. Dataset files are not included in this repository.

This keeps the repository smaller and avoids distributing the full dataset alongside the application code.

## Limitations

PocketScope is a research and development prototype. Its screening and image analysis results are intended for preliminary investigation and demonstration only.

The system is **not a replacement for laboratory testing, clinical diagnosis, or professional medical assessment**.

Image quality, sample preparation, model performance, and the available training data can all affect the results.

## Current Status

The project is under active development. The Flutter application and Python image analysis components are being developed together as a prototype for portable sample screening.

## License

A license has not yet been selected for this project.
