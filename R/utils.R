#' Check if a package is installed and load it
#'
#' This function checks if a specified package is installed in the R environment.
#' If the package is not installed, it will be automatically installed. After
#' installation (if necessary), the package is loaded into the session.
#'
#' @param package_name A string with the name of the package to check and load.
#'
#' @return Invisibly returns `TRUE` if the package is successfully loaded or installed and loaded.
#' If the installation or loading fails, an error will be raised.
#' @import utils
#' @importFrom glue glue
#'
#' @examples
#' \dontrun{
#' check_and_load_package("httr2")
#' check_and_load_package("xml2")
#' }
#'
#' @export
check_and_load_package <- function(package_name) {
  # Check if the package is installed
  if (!requireNamespace(package_name, quietly = TRUE)) {
    message(glue::glue("Package '{package_name}' is not installed. Installing now..."))
    install.packages(package_name)
    message(glue::glue("Package '{package_name}' installed successfully."))
  }

  # Check if the package is already loaded
  if (!package_name %in% loadedNamespaces()) {
    message(glue::glue("Loading package '{package_name}'..."))
    # Load the package, suppressing startup messages
    suppressPackageStartupMessages(
      library(package_name, character.only = TRUE)
    )
  }
}

#' Handle HTTP response from OwnCloud
#'
#' This function processes the response from the WebDAV server, checking for errors.
#'
#' @param response The response object from an `httr2` request.
#'
#' @return The processed response content if successful, or an error if the request failed.
#'
#' @export
handle_response <- function(response) {
  # Check for HTTP errors
  if (response$status_code >= 400) {
    stop("HTTP request failed with status: ", response$status_code, " - ", response$status_msg)
  }

  # Return the response content
  response
}
