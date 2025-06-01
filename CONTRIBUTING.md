# Contributing to project

This guide is for anyone willing to contribute to this repository.

## Requirements

- Python3

## Installing pre-commit hooks

This repository uses pre-commit hooks which are **scripts that run before every commit** and are triggered when you run the `git commit` command. In our case, they intend to format and lint the committed files so they stay consistent, and help avoiding YAML errors.

Optional: Create and activate a new virtual environment:

```sh
$ python3 -m venv .venv
$ source .venv/bin/activate
```

Install dependencies:

```sh
$ pip3 install -r requirements.txt
```

Install pre-commit:

```sh
$ pre-commit install
```

## How To

Activate the Python virtual environment:

```sh
$ source .venv/bin/activate
```

Deactivate the Python virtual environment:

```sh
$ deactivate
```

Remove the Python virtual environment:

```sh
$ deactivate
$ rm -rf .venv
```

## Linting and formatting

Make sure you activated the Python virtual environment every time you commit files in this repository.

You can test the pre-commit hooks by staging the files you want to check:

```sh
$ git add <file>
```

And running the pre-commit hooks:

```sh
$ pre-commit run
```

If the pre-commit check fails, you have to fix your files if needed, stage them again and run the tests again.
