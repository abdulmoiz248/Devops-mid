# app/utils/csv_validator.py

import csv
import re

REQUIRED_COLUMNS = ['Serial Number', 'Product Name', 'Input Image Urls']
URL_REGEX = re.compile(
    r'^(?:http|ftp)s?://'  # http:// or https://
    r'(?:(?:[A-Z0-9](?:[A-Z0-9-]{0,61}[A-Z0-9])?\.)+(?:[A-Z]{2,6}\.?|[A-Z0-9-]{2,}\.?)|'  # domain...
    r'localhost|'  # localhost...
    r'\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}|'  # ...or ipv4
    r'\[?[A-F0-9]*:[A-F0-9:]+\]?)'  # ...or ipv6
    r'(?::\d+)?'  # optional port
    r'(?:/?|[/?]\S+)$', re.IGNORECASE)

def validate_csv(file_path):
    """Validates the CSV file for correct format and URL structure."""
    errors = []

    with open(file_path, 'r') as csv_file:
        reader = csv.DictReader(csv_file)
        headers = reader.fieldnames

        # Check for required columns
        if not all(column in headers for column in REQUIRED_COLUMNS):
            errors.append(f"CSV file must contain the following columns: {', '.join(REQUIRED_COLUMNS)}")
            return False, errors

        # Validate each row
        for row_number, row in enumerate(reader, start=1):
            if not row['Serial Number']:
                errors.append(f"Row {row_number}: 'Serial Number' is required.")
            if not row['Product Name']:
                errors.append(f"Row {row_number}: 'Product Name' is required.")
            if not row['Input Image Urls']:
                errors.append(f"Row {row_number}: 'Input Image Urls' is required.")
            else:
                image_urls = row['Input Image Urls'].split(',')
                for url in image_urls:
                    if not re.match(URL_REGEX, url.strip()):
                        errors.append(f"Row {row_number}: Invalid URL format in 'Input Image Urls': {url.strip()}")

    if errors:
        return False, errors

    return True, []

