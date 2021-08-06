This is a dart command package to delete the old versions of the packages in pub-cache and keep only the latest version.

* [Installation](#installation)
* [Usage](#usage)
* [Execution example](#execution-example)

## Installation

```
% [dart|flutter] pub global activate purge_pub_cache
```

## Usage

`% [dart|flutter] pub global run purge_pub_cache`

```
Usage: purge_pub_cache [option...]

Options:
-h, --help                Show this usage.
    --version             Show app version and exit.
-d, --directory=<path>    Specify a path to handle as pub_cache directory.
-y, --yes                 Assume YES to confirm the deletion.
-q, --quiet               No outputs (--yes is assumed to be set).
-n, --dry-run             Dry-run. Show the packages to delete and exit.
```

## Execution example

Suppose fooPackage has version 0.0.1, 0.0.2, 0.0.3 and barPackage has 1.8.0, 1.8.1, in pub-cache.

```
% pub global run purge_pub_cache
Using pub-cache directory: /home/foo/.pub-cache

Packages to be deleted:
fooPackage: 0.0.1, 0.0.2
barPackage: 1.8.0

Are you sure to delete these 3 packages? [y/N]: y
Deleting 3 packages... done.
```
