#' Sign a PDF Document using the BatchPDFSign Java JAR
#'
#' This function signs a PDF document by calling the `BatchPDFSignPortable.jar` Java archive
#' through a system command. It constructs a command to execute the JAR and sign the
#' PDF based on the provided parameters, including keystore information, signature position,
#' font size, and optionally signature text, reason for signing, and location of the signing.
#'
#' @param pdf_file A string representing the path to the input PDF file that needs to be signed.
#' @param output_file A string representing the path where the signed PDF will be saved.
#' @param fs A numeric value indicating the font size of the signature text. Default is 7.
#' @param rh A numeric value representing the rectangle height of the signature area. Default is 20.
#' @param rw A numeric value representing the rectangle width of the signature area. Default is 600.
#' @param rx A numeric value representing the X coordinate of the signature's position. Default is 5.
#' @param ry A numeric value representing the Y coordinate of the signature's position. Default is 5.
#' @param page A numeric value indicating the page number where the signature will be placed. Default is 1.
#' @param signtext An optional string representing the custom text to be included in the signature.
#' @param validate_link An optional string representing the link to a app to validate the document.
#' @param keystore_path A string representing the path to the keystore (e.g., a .p12 file) containing the signing key and certificate. Defaults to the environment variable `KEYSTORE_PATH`.
#' @param keystore_password A string representing the password for accessing the keystore. Defaults to the environment variable `KEY_PASSWORD`.
#' @param translate A boolean indicating whether the signature text should be translated to Portuguese. Default is FALSE (English).
#'
#' @return The function does not return a value but generates a signed PDF at the specified output path.
#' If any error occurs, it will stop and display an appropriate error message.
#' @importFrom clock date_now date_format clock_locale
#' @importFrom stringr str_detect
#' @examples
#' \dontrun{
#' sign_pdf(
#'   pdf_file = "input.pdf",
#'   output_file = "signed_output.pdf",
#'   keystore_path = "keystore.p12",
#'   keystore_password = "password",
#'   signtext = "Digitally signed by Company",
#'   validate_link = "apps.sepe.pe.gov.br/validate",
#'   translate = TRUE,
#' )
#' }
#' @export
sign_pdf <- function(pdf_file, output_file, fs = 7, rh = 20, rw = 600, rx = 5, ry = 5,
                     page = 1, signtext = NULL, validate_link = NULL,
                     keystore_path = Sys.getenv("KEYSTORE_PATH"),
                     keystore_password = Sys.getenv("KEY_PASSWORD"),
                     translate = FALSE) {

  if (Sys.info()["sysname"] == "Windows") {
    stop("This package is only supported on Linux and macOS.")
  }

  check_and_load_package("glue")
  check_and_load_package("clock")

  # Input parameter validation
  if (!file.exists(pdf_file)) {
    stop("The specified PDF file does not exist: ", pdf_file)
  }

  if (!dir.exists(dirname(output_file))) {
    stop("The output directory does not exist: ", dirname(output_file))
  }

  if (!file.exists(keystore_path)) {
    stop("The specified keystore does not exist: ", keystore_path)
  }

  pdf_file <- path.expand(pdf_file)
  output_file <- path.expand(output_file)
  keystore_path <- path.expand(keystore_path)

  if (nchar(keystore_password) == 0) {
    stop("The keystore password cannot be empty.")
  }

  if (!file.exists(jar_path <- system.file("ext", "BatchPDFSignPortable.jar", package="signer"))) {
    stop("The 'BatchPDFSignPortable.jar' file was not found in the package.")
  }

  if (!is.numeric(page) || page <= 0) {
    stop("Page number must be a numeric value greater than 0.")
  }

  # Get the current date
  hoje <- date_now(zone = "America/Recife")

  # Conditionally add optional parameters if they are not NULL or empty
  flag_signtext <- !is.null(signtext) && nchar(signtext) > 0
  if (flag_signtext) {
    if (translate) {
      # Format the date in Portuguese
      signtext <- glue(signtext, date_format(hoje, format = "Data e hora: %A, %d de %B de %Y, %H:%M:%S.", locale = clock_locale("pt")))
      if (!is.null(validate_link) && nchar(validate_link) > 0) {
        signtext <- paste(signtext, sprintf('\n Validar documento em: "%s"', validate_link))
        rh <- rh + 20
      }
    } else {
      # Format the date in English (default)
      signtext <- glue(signtext, date_format(hoje, format = "Date and Time: %A, %d %B %Y, %H:%M:%S.", locale = clock_locale("en")))
      if (!is.null(validate_link) && nchar(validate_link) > 0) {
        signtext <- paste(signtext, sprintf('\n Validate document at: "%s"', validate_link))
        rh <- rh + 20
      }
    }
  }

  # Start building the command
  cmd <- sprintf(
    '-jar %s --page %s --fs %s --rh %s --rw %s --rx %s --ry %s -k %s -p %s -i %s -o %s',
    jar_path, page, fs, rh, rw, rx, ry, keystore_path, keystore_password, pdf_file, output_file
  )

  # Conditionally add optional parameters if they are not NULL or empty
  if (flag_signtext) {
    cmd <- paste(cmd, sprintf('--signtext "%s"', signtext))
  }

  # Execute the command and handle errors
  res <- system2("java", args = cmd, stdout = FALSE, stderr = NULL)
  # Check the result of the command execution
  if (res != 0) {
    stop("Failed to execute the signing command. Return code: ", res)
  } else {
    message("PDF successfully signed: ", output_file)
  }
}

#The output can be optionally translated to Portuguese.
#' Verifies the digital signature of a PDF file using pdfsig
#'
#' This function uses the `pdfsig` command to check the digital signatures
#' of a PDF file.
#'
#' @param pdf_file The path to the PDF file to be verified.
#' @return A named list containing the parsed information about the digital signatures, or a message that no signatures were found.
#' @importFrom stringr str_detect
#' @examples
#' \dontrun{verify_pdf_signature("document.pdf")}
#' @export
verify_pdf_signature <- function(pdf_file) { #translate = FALSE
  # Ensure full path is expanded
  pdf_file <- path.expand(pdf_file)
  check_and_load_package("stringr")

  if (Sys.info()["sysname"] == "Windows") {
    stop("This package is only supported on Linux and macOS.")
  }

  # Check if 'pdfsig' is installed
  if (system2("which", "pdfsig", stdout = TRUE) == "") {
    stop("'pdfsig' command is not installed on the system. Please install it before using this function.")
  }

  # Check if the PDF file exists
  if (!file.exists(pdf_file)) {
    stop("The specified PDF file was not found.")
  }

  # Run the pdfsig command and capture the output and error
  result <- tryCatch({
    output <- suppressWarnings(system2("pdfsig", args = pdf_file, stdout = TRUE, stderr = TRUE))
    if (str_detect(output[1], "does not contain any signatures"))
      return(list(message = "No signatures found in the PDF."))
    output
  }, error = function(e) {
    return(list(message = "Error while executing the pdfsig command."))
  })

  # # Função para traduzir as linhas, com ajuste na ordem das traduções
  # translate_line <- function(line) {
  #   # Traduções mais longas primeiro para evitar substituições parciais
  #   translations <- list(
  #     "Signature is Valid." = "Assinatura é válida.",
  #     "Signature is invalid!" = "Assinatura é inválida!",
  #     "Certificate issuer is unknown." = "Emissor do certificado é desconhecido.",
  #     "The signature form field is not signed." = "O campo de formulário da assinatura não está assinado.",
  #     "Signature" = "Assinatura",
  #     "Signer Certificate Common Name" = "Nome Comum do Certificado do Assinante",
  #     "Signer full Distinguished Name" = "Nome Distinto Completo do Assinante",
  #     "Signing Time" = "Data e Hora da Assinatura",
  #     "Signing Hash Algorithm" = "Algoritmo de Hash da Assinatura",
  #     "Signature Type" = "Tipo de Assinatura",
  #     "Signed Ranges" = "Intervalos Assinados",
  #     "Signature Validation" = "Validação da Assinatura",
  #     "Certificate Validation" = "Validação do Certificado",
  #     "Total document signed" = "Documento Totalmente Assinado"
  #   )
  #
  #   for (en in names(translations)) {
  #     line <- gsub(en, translations[[en]], line, fixed = TRUE)
  #   }
  #
  #   return(line)
  # }

  # Parse the result to handle multiple signatures and invalid signatures
  parsed_list <- list()
  current_signature <- list()
  signature_count <- 0

  # Loop through each line of the result
  for (line in result) {
    if (grepl("^Signature #", line)) {
      # If we already have data from a previous signature, add it to the list
      if (length(current_signature) > 0) {
        parsed_list[[paste0("Signature_", signature_count)]] <- current_signature
      }
      # Reset for the new signature
      current_signature <- list()
      signature_count <- signature_count + 1
      current_signature[["Signature"]] <- line
    } else if (grepl("Signature Field Name:", line)) {
      current_signature[["Field Name"]] <- sub("  - Signature Field Name: ", "", line)
    } else if (grepl("Signer Certificate Common Name:", line)) {
      current_signature[["Signer"]] <- sub("  - Signer Certificate Common Name: ", "", line)
    } else if (grepl("Signer full Distinguished Name:", line)) {
      current_signature[["Distinguished Name"]] <- sub("  - Signer full Distinguished Name: ", "", line)
    } else if (grepl("Signing Time:", line)) {
      current_signature[["Signing Time"]] <- sub("  - Signing Time: ", "", line)
    } else if (grepl("Signing Hash Algorithm:", line)) {
      current_signature[["Hash Algorithm"]] <- sub("  - Signing Hash Algorithm: ", "", line)
    } else if (grepl("Signature Type:", line)) {
      current_signature[["Signature Type"]] <- sub("  - Signature Type: ", "", line)
    } else if (grepl("Signed Ranges:", line)) {
      current_signature[["Signed Ranges"]] <- sub("  - Signed Ranges: ", "", line)
    } else if (grepl("Total document signed", line)) {
      current_signature[["Total Document Signed"]] <- TRUE
    } else if (grepl("Signature Validation:", line)) {
      current_signature[["Signature Validation"]] <- sub("  - Signature Validation: ", "", line)
    } else if (grepl("Certificate Validation:", line)) {
      current_signature[["Certificate Validation"]] <- sub("  - Certificate Validation: ", "", line)
    } else if (grepl("The signature form field is not signed", line)) {
      current_signature[["Invalid Signature"]] <- "The signature form field is not signed."
    }
  }

  # Add the last signature parsed
  if (length(current_signature) > 0) {
    parsed_list[[paste0("Signature_", signature_count)]] <- current_signature
  }

  # If no signatures were parsed, return the message
  if (length(parsed_list) == 0) {
    return(list(message = "No signatures found in the PDF."))
  }

  # Translate if necessary
  # if (translate) {
  #   parsed_list <- lapply(parsed_list, function(sig) {
  #     lapply(sig, translate_line)
  #   })
  # }

  # Return the parsed named list with all signatures
  return(parsed_list)
}


