
# signer

**signer** is an R package that lets you digitally sign PDF documents and verify digital signatures in PDFs. It uses external tools like `BatchPDFSignPortable.jar` for signing and `pdfsig` (part of the Poppler library) for verifying signatures.

## Installation

You can install the package directly from GitHub:

```r
# Install the package directly from GitHub
devtools::install_github("StrategicProjects/signer")
```

## Features

This package provides two main functionalities:

### 1. `sign_pdf()`

The `sign_pdf()` function allows you to digitally sign a PDF document using the `BatchPDFSignPortable.jar` file. The signature can include custom text, and you can control the positioning of the signature in the document.

#### Usage Example:

```r
sign_pdf(
  pdf_file = "input.pdf",
  output_file = "signed_output.pdf",
  keystore_path = "keystore.p12",
  keystore_password = "password",
  signtext = "Document digitally signed by CastLab",
  validate_link = "http://castlab.org/validate",
  translate = TRUE
)
```

#### Parameters:

- **`pdf_file`**: Path to the input PDF file.
- **`output_file`**: Path where the signed PDF will be saved.
- **`fs`, `rh`, `rw`, `rx`, `ry`**: Font size, height, width, and signature coordinates.
- **`page`**: Page number where the signature will be placed.
- **`signtext`**: Custom text to include in the signature.
- **`validate_link`**: Optional link for validating the signed document.
- **`keystore_path`**: Path to the `.p12` file containing the key and certificate.
- **`keystore_password`**: Password for the `.p12` file.
- **`translate`**: If `TRUE`, the signature text will be in Portuguese; otherwise, it will be in English (default).

### 2. `verify_pdf_signature()`

The `verify_pdf_signature()` function checks the digital signatures in a PDF using the `pdfsig` command. You can also choose to translate the output to Portuguese.

#### Usage Example:

```r
result <- verify_pdf_signature("signed_document.pdf", translate = TRUE)
print(result)
```

#### Parameters:

- **`pdf_file`**: Path to the PDF file to be verified.
- **`translate`**: If `TRUE`, translates the output to Portuguese; otherwise, the result is in English.

## Dependencies

This package is supported only on Linux and macOS. It requires the following external tools:

- **Java**: Required to run `BatchPDFSignPortable.jar` for signing PDFs.
- **Poppler**: To verify signatures using `pdfsig`, Poppler must be installed on the system. `pdfsig` is part of the Poppler library (https://poppler.freedesktop.org/).

### Installing `Poppler` on Linux:

```bash
sudo apt-get install poppler-utils
```

### Installing `Poppler` on macOS (via Homebrew):

```bash
brew install poppler
```

## Generating a Certificate using Command Line

You can also generate a digital certificate from the command line using OpenSSL. Here are the steps:

### Generate a private key:

```bash
openssl genrsa -aes128 -out private_key.key 2048
```

### Create a Certificate Signing Request (CSR):

```bash
openssl req -new -days 365 -key private_key.key -out request.csr
```

### Generate a self-signed certificate:

```bash
openssl x509 -in request.csr -out certificate.crt -req -signkey private_key.key -days 365
```

### Export the certificate to PKCS#12 format:

```bash
openssl pkcs12 -export -out certificate.pfx -inkey private_key.key -in certificate.crt
```

## Credits

This package uses two external tools for signing and verifying PDF documents:

1. **BatchPDFSignPortable.jar**: Developed by Josep Marxuach (https://github.com/jmarxuach/BatchPDFSign), `BatchPDFSign` is a Java utility for signing PDF documents.
2. **pdfsig**: Part of the Poppler library, `pdfsig` is a command-line tool used to verify signatures in PDF documents. The Poppler project is maintained by the Poppler developer community (https://poppler.freedesktop.org/).

## License

This package is distributed under the GPL-3 license. See the `LICENSE` file for more information.
