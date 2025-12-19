# Contributing to PVgravID

Thank you for your interest in contributing to PVgravID! This document
provides guidelines and instructions for contributing to the project.

## Getting Started

### Prerequisites

- R (\>= 3.5)
- RStudio (recommended)
- Git

### Required R Packages

The package depends on several R packages. The main dependency is
[DiAna](https://github.com/fusarolimichele/DiAna), which is not on CRAN
but available on GitHub.

## Development Setup

### 1. Fork and Clone

``` bash
# Fork the repository on GitHub, then clone your fork
git clone https://github.com/YOUR-USERNAME/pv_mater.git
cd pv_mater
```

### 2. Install Development Dependencies

``` r

# Install devtools if you don't have it
install.packages("devtools")

# Install package dependencies (including DiAna from GitHub)
devtools::install_deps(dependencies = TRUE)

# Install development tools
install.packages(c("testthat", "lintr", "styler"))
```

### 3. Load the Package

``` r

# Load all package functions
devtools::load_all()

# Run tests
devtools::test()
```

## Coding Standards

We follow the **tidyverse style guide** for R code. Please ensure your
code adheres to these standards before submitting.

### Style Guide

- Use 2 spaces for indentation (never tabs)
- Maximum line length: 120 characters
- Use `snake_case` for function and variable names
- Use `<-` for assignment, not `=`
- Put spaces around operators (`x + y`, not `x+y`)
- Use double quotes for strings (`"text"`, not `'text'`)

### Automatic Formatting

Before submitting code, run `styler` to automatically format your code:

``` r

# Format a single file
styler::style_file("R/your_file.R")

# Format all R files
styler::style_dir("R")

# Format test files
styler::style_dir("tests/testthat")
```

### Linting

Check your code for style issues:

``` r

# Lint the entire package
lintr::lint_package()

# Lint a specific file
lintr::lint("R/your_file.R")
```

## Testing

All new features must include tests.

### Running Tests

``` r

# Run all tests
devtools::test()

# Run a specific test file
testthat::test_file("tests/testthat/test-pregnancy_algorithms.R")
```

### Writing Tests

- Place test files in `tests/testthat/`
- Name test files `test-<function_name>.R`
- Use descriptive test names with `test_that()`
- Test both expected behavior and edge cases
- Use sample data from DiAna package (`database = "sample"`)

## Pull Request Process

### Before Submitting

Run the local checks to ensure your changes pass all tests:

``` r

devtools::load_all()
devtools::check()
devtools::test()
styler::style_dir("R")
styler::style_dir("tests/testthat")
lintr::lint_package()
```

This script runs:

1.  R CMD check (package validation)
2.  Linting (code style)
3.  Tests (testthat)

All checks must pass before submitting a PR.

### Submitting a Pull Request

1.  **Create a branch** for your changes:

    ``` bash
    git checkout -b feature/your-feature-name
    ```

2.  **Make your changes** following the coding standards

3.  **Add tests** for your changes

4.  **Update documentation**:

    ``` r

    # Update function documentation with roxygen2
    devtools::document()
    ```

5.  **Run local checks**:

    Check that all tests pass and code is lint-free.

    ``` r

    devtools::load_all()
    devtools::check()
    devtools::test()
    styler::style_dir("R")
    styler::style_dir("tests/testthat")
    lintr::lint_package()
    ```

6.  **Commit your changes**:

    ``` bash
    git add .
    git commit -m "feat: Brief description of your changes"
    ```

7.  **Push to your fork**:

    ``` bash
    git push origin feature/your-feature-name
    ```

8.  **Open a Pull Request** on GitHub with:

    - Clear description of changes
    - Reference to any related issues
    - Confirmation that all checks pass

### PR Review Process

- Maintainers will review your PR
- GitHub Actions will automatically run checks
- Address any feedback or requested changes
- Once approved, maintainers will merge your PR

## Documentation

### Function Documentation

Use roxygen2 comments for all exported functions:

``` r

#' Short description of function
#'
#' Longer description with more details about what the function does.
#'
#' @param database Database name (e.g., "24Q4", "VigiBase", "sample")
#' @param pids_vct Vector of primary IDs
#'
#' @return Description of return value
#'
#' @examples
#' \dontrun{
#' result <- my_function(database = "sample", pids_vct = c(1, 2, 3))
#' }
#'
#' @export
my_function <- function(database, pids_vct) {
  # function code
}
```

### Updating Documentation

After modifying function documentation:

``` r

devtools::document()
```

## Project Structure

``` text
pv_mater/
├── R/                          # R source code
│   ├── check_pregnancy_criteria.R
│   ├── flowchart_generator.R
│   ├── globals.R
│   ├── modular_data.R
│   ├── render_Upset.R
│   ├── render_Venn.R
│   └── ...
├── tests/
│   └── testthat/              # Test files
├── man/                       # Generated documentation
├── .github/workflows/         # CI/CD workflows
├── DESCRIPTION               # Package metadata
├── NAMESPACE                 # Auto-generated
└── README.md
```

## Questions and Support

- **Issues**: Open an issue on GitHub for bugs or feature requests
- **Discussions**: Use GitHub Discussions for questions
- **Email**: Contact the maintainers (see DESCRIPTION file)

## Recognition

Contributors will be acknowledged in the package documentation and/or
publications as appropriate.

Thank you for contributing to PVgravID!
