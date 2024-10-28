# Contributing to Linx

We are happy to accept community contributions to help linx become more intuitive,
efficient, and portable.

The objective of this document is to provide newcomers a meaningful way to get engaged and contribute.


## Table of Contents

* [Coding Style](#coding-style)
    * [File Structure](#file-structure)
    * [Documentation](#documentation)
* [Testing](#testing)
    * [Running tests](#running-tests)
    * [Writing tests](#writing-tests)
* [Getting your merge request accepted](#getting-your-merge-request-accepted)


## Coding Style

This section specifies the conventions used in the source code.
We are still in the process of defining linx development guidelines, so feel free to share any ideas you'd
like us to consider or revisit.

### File Structure

Each code file should contain, in this order:

1. The MIT license header, followed by a blank line
2. The initialization steps (if any)
3. The constants
4. The input parameters
5. The function definitions
6. The procedural code consuming these functions

#### Indentation

Code is indented using four spaces. Tab characters are not allowed for indenting code.

#### Naming conventions

- Identifier names (variables and functions) use snake_case.
- Constants and environment variables use UPPER_SNAKE_CASE.

#### Filename conventions

Bash filenames use lower-kebab-case.

### Documentation

Although "good code is self-documenting", it is incredibly easy to forget what your code
(or someone else's) intended.

A function should be commented when their purpose, potential side effects, or parameters
would benefit from being clarified.

## Testing

Before merging a pull request, the tests should pass.

### Running tests

To run the unit tests, verify that `Docker` is installed:

```
docker --version
```

#### Automated tests

Then execute the following file:

```
./tests/run-tests.sh
```

This script automatically creates a Docker image from the latest version of the software, builds a container from that
image, and run the tests. Because it is idempotent; you can run it as many times as you like without cluttering your
Docker images and containers or messing with your own file system.

The first time you run the script, it might take a little longer to complete.
After that initial run, subsequent executions should only take a few seconds.

You can monitor the test results directly in your terminal as they run.

#### Manual tests

To manually test linx features, run the tests in interactive mode:

```
./tests/run-tests.sh -i
```

This will allow you to interact with the container and manually test linx commands in an isolated environment.

### Writing tests

To test your code, open the file that contains the test suite you wish to update, and add new tests or update 
existing ones as needed.
The test suites are located in `tests/suites`: these functions are the core of our testing suite, and your 
contributions help us identify issues early and maintain a stable and robust application.

Writing a new test is straightforward:

1. Define the test function
```
function feature_expected_result {
    # Given
        # test preconditions
    # When
        # linx feature under test
    # Then
    if [[ ... failing condition ... ]]; then
        echo "Failed: feature_expected_result"
        exit 1
    fi
}
```

2. Pass your function to the `TESTS_TO_RUN` array at the top of the file
```
declare -a TESTS_TO_RUN=(
    # List of declared tests...
    'feature_expected_result' # your new test
) 
```

## Getting your merge request accepted

To contribute your code:

1. Fork the project from the `master` branch
2. Create a new branch named `feature/branch-name` for a new feature, or `bugfix/branch-name` for fixing a bug
3. Create one or more commits on your branch
4. Submit your merge request back into `master` with a brief description of your contributions
