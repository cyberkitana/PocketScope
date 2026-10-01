from flask import Flask, request, jsonify
from pathlib import Path
import base64
import json
import subprocess
import sys
import tempfile
import traceback


app = Flask(__name__)

BASE_DIR = Path(__file__).resolve().parent
PREDICT_SCRIPT = BASE_DIR / "predict_image.py"


@app.route("/health", methods=["GET"])
def health():
    return jsonify({
        "success": True,
        "message": "Python analysis server is running.",
    })


def extract_json_from_stdout(stdout_text):
    """
    predict_image.py should return JSON, but libraries such as YOLO
    can also print diagnostic messages to stdout.

    This function searches the output for a valid JSON object instead
    of assuming the entire stdout is JSON.
    """

    if not stdout_text:
        return None

    text = stdout_text.strip()

    # First try the entire output.
    try:
        decoded = json.loads(text)

        if isinstance(decoded, dict):
            return decoded
    except json.JSONDecodeError:
        pass

    # Try each line from the bottom.
    # predict_image.py normally prints the final JSON on one line.
    lines = [
        line.strip()
        for line in text.splitlines()
        if line.strip()
    ]

    for line in reversed(lines):
        try:
            decoded = json.loads(line)

            if isinstance(decoded, dict):
                return decoded
        except json.JSONDecodeError:
            continue

    # Last fallback:
    # Look for JSON objects embedded inside other console output.
    for start_index in range(len(text) - 1, -1, -1):
        if text[start_index] != "{":
            continue

        candidate = text[start_index:].strip()

        try:
            decoded = json.loads(candidate)

            if isinstance(decoded, dict):
                return decoded
        except json.JSONDecodeError:
            continue

    return None


@app.route("/analyze", methods=["POST"])
def analyze():
    temp_input = None
    temp_output = None

    print("")
    print("=" * 70)
    print("NEW ANALYSIS REQUEST")
    print("=" * 70)

    try:
        # ------------------------------------------------------------------
        # CHECK REQUEST
        # ------------------------------------------------------------------

        if "image" not in request.files:
            print("ERROR: No image was included in the request.")

            return jsonify({
                "success": False,
                "error": "No image was included in the request.",
            }), 400

        uploaded_image = request.files["image"]

        if uploaded_image.filename is None:
            print("ERROR: Uploaded image has no filename.")

            return jsonify({
                "success": False,
                "error": "Uploaded image has no filename.",
            }), 400

        print(
            f"Received image: {uploaded_image.filename}"
        )

        # ------------------------------------------------------------------
        # CREATE TEMPORARY FILES
        # ------------------------------------------------------------------

        input_suffix = Path(
            uploaded_image.filename
        ).suffix.lower()

        if not input_suffix:
            input_suffix = ".jpg"

        with tempfile.NamedTemporaryFile(
            delete=False,
            suffix=input_suffix,
        ) as input_file:
            temp_input = Path(input_file.name)

        with tempfile.NamedTemporaryFile(
            delete=False,
            suffix=".jpg",
        ) as output_file:
            temp_output = Path(output_file.name)

        uploaded_image.save(temp_input)

        print(
            f"Input image: {temp_input}"
        )

        print(
            f"Output image: {temp_output}"
        )

        print(
            f"Prediction script: {PREDICT_SCRIPT}"
        )

        # ------------------------------------------------------------------
        # CHECK PREDICTION SCRIPT
        # ------------------------------------------------------------------

        if not PREDICT_SCRIPT.exists():
            error_message = (
                "predict_image.py could not be found at: "
                f"{PREDICT_SCRIPT}"
            )

            print(
                f"ERROR: {error_message}"
            )

            return jsonify({
                "success": False,
                "error": error_message,
            }), 500

        # ------------------------------------------------------------------
        # RUN COMPUTER VISION MODEL
        # ------------------------------------------------------------------

        command = [
            sys.executable,
            str(PREDICT_SCRIPT),
            str(temp_input),
            str(temp_output),
        ]

        print("")
        print("RUNNING PREDICTION SCRIPT:")
        print(" ".join(command))
        print("")

        result = subprocess.run(
            command,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
        )

        stdout_text = result.stdout or ""
        stderr_text = result.stderr or ""

        print("")
        print("-" * 70)
        print("PREDICT SCRIPT STDOUT")
        print("-" * 70)
        print(stdout_text)

        print("")
        print("-" * 70)
        print("PREDICT SCRIPT STDERR")
        print("-" * 70)
        print(stderr_text)

        print("")
        print("-" * 70)
        print(f"EXIT CODE: {result.returncode}")
        print("-" * 70)

        # ------------------------------------------------------------------
        # CHECK PYTHON SCRIPT RESULT
        # ------------------------------------------------------------------

        if result.returncode != 0:
            error_message = (
                "The computer analysis script failed."
            )

            if stderr_text.strip():
                error_message += (
                    f"\n\n{stderr_text.strip()}"
                )

            elif stdout_text.strip():
                error_message += (
                    f"\n\n{stdout_text.strip()}"
                )

            print("")
            print(
                f"ERROR: {error_message}"
            )

            return jsonify({
                "success": False,
                "error": error_message,
            }), 500

        # ------------------------------------------------------------------
        # PARSE JSON RESULT
        # ------------------------------------------------------------------

        analysis_result = extract_json_from_stdout(
            stdout_text
        )

        if analysis_result is None:
            print("")
            print(
                "ERROR: Could not find valid JSON "
                "inside predict_image.py output."
            )

            return jsonify({
                "success": False,
                "error": (
                    "Computer analysis returned invalid JSON. "
                    "The prediction script completed, but the "
                    "analysis result could not be read."
                ),
                "raw_output": stdout_text[-5000:],
            }), 500

        print("")
        print("JSON RESULT SUCCESSFULLY PARSED.")

        # ------------------------------------------------------------------
        # CHECK WHETHER PREDICTION SCRIPT REPORTED AN ERROR
        # ------------------------------------------------------------------

        if analysis_result.get("success") is not True:
            error_message = (
                analysis_result.get("error")
                or "Computer analysis failed."
            )

            print(
                f"Prediction script reported an error: "
                f"{error_message}"
            )

            return jsonify({
                "success": False,
                "error": str(error_message),
            }), 500

        # ------------------------------------------------------------------
        # CHECK ANALYSED IMAGE
        # ------------------------------------------------------------------

        annotated_image_path = analysis_result.get(
            "annotated_image_path"
        )

        if annotated_image_path:
            annotated_path = Path(
                str(annotated_image_path)
            )
        else:
            annotated_path = temp_output

        if not annotated_path.exists():
            print("")
            print(
                "ERROR: Annotated image was not created."
            )

            return jsonify({
                "success": False,
                "error": (
                    "Computer analysis completed, "
                    "but the analysed image was not created."
                ),
            }), 500

        print(
            f"Annotated image found: "
            f"{annotated_path}"
        )

        # ------------------------------------------------------------------
        # CONVERT ANALYSED IMAGE TO BASE64
        # ------------------------------------------------------------------

        annotated_bytes = annotated_path.read_bytes()

        annotated_base64 = base64.b64encode(
            annotated_bytes
        ).decode("utf-8")

        analysis_result[
            "annotated_image_base64"
        ] = annotated_base64

        # The original uploaded image is the image used
        # for computer analysis.
        analysis_result[
            "input_image_path"
        ] = str(temp_input)

        # Keep the path for debugging/reference.
        analysis_result[
            "annotated_image_path"
        ] = str(annotated_path)

        # ------------------------------------------------------------------
        # RETURN RESULT TO FLUTTER
        # ------------------------------------------------------------------

        print("")
        print(
            "Analysis completed successfully."
        )

        print(
            f"Cells assessed: "
            f"{analysis_result.get('cells_assessed')}"
        )

        print(
            f"RBC count: "
            f"{analysis_result.get('counts', {}).get('RBC')}"
        )

        print(
            f"WBC count: "
            f"{analysis_result.get('counts', {}).get('WBC')}"
        )

        print(
            f"Platelet count: "
            f"{analysis_result.get('counts', {}).get('Platelets')}"
        )

        print(
            f"Sickle-like count: "
            f"{analysis_result.get('sickle_like_count')}"
        )

        print("=" * 70)
        print("ANALYSIS REQUEST COMPLETE")
        print("=" * 70)
        print("")

        return jsonify(
            analysis_result
        ), 200

    except Exception as error:
        print("")
        print("=" * 70)
        print("SERVER ERROR")
        print("=" * 70)

        print(
            f"{type(error).__name__}: {error}"
        )

        traceback.print_exc()

        print("=" * 70)
        print("")

        return jsonify({
            "success": False,
            "error": (
                f"{type(error).__name__}: "
                f"{error}"
            ),
        }), 500

    finally:
        # ------------------------------------------------------------------
        # CLEAN UP TEMPORARY INPUT
        # ------------------------------------------------------------------

        if temp_input is not None:
            try:
                if temp_input.exists():
                    temp_input.unlink()
            except Exception as cleanup_error:
                print(
                    f"Could not remove temporary "
                    f"input file: {cleanup_error}"
                )

        # ------------------------------------------------------------------
        # CLEAN UP TEMPORARY OUTPUT
        # ------------------------------------------------------------------

        if temp_output is not None:
            try:
                if temp_output.exists():
                    temp_output.unlink()
            except Exception as cleanup_error:
                print(
                    f"Could not remove temporary "
                    f"output file: {cleanup_error}"
                )


if __name__ == "__main__":
    print("")
    print("=" * 70)
    print("POCKETSCOPE PYTHON ANALYSIS SERVER")
    print("=" * 70)
    print(f"Server directory: {BASE_DIR}")
    print(f"Prediction script: {PREDICT_SCRIPT}")
    print("")
    print("Starting server on port 5000...")
    print("=" * 70)
    print("")

    app.run(
        host="0.0.0.0",
        port=5000,
        debug=False,
    )