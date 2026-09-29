import cv2


def load_image(image_path):
    """
    Load an image from the supplied file path.
    """

    image = cv2.imread(image_path)

    if image is None:
        raise FileNotFoundError(
            f"Could not load image: {image_path}"
        )

    return image


def get_image_dimensions(image):
    """
    Return the width and height of an image.
    """

    height, width = image.shape[:2]

    return width, height