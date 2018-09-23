# LightGBM Online Installer

This is Laurae's LightGBM online installer: it allows to install LightGBM from source directly from your R terminal.

Please go to branch `pre-2.2.0` for a LightGBM version below 2.2.0.

## Installation

```r
devtools::install_github("Laurae2/lgbdl")
```

## Pre-requisites

You need to define the proper compiler to use. It could be:

* gcc (if using Linux or Rtools + MinGW)
* Visual Studio 15 2017 Win64 (Rtools + Visual Studio)

In addition, specific software must be installed for Windows:

- git (Windows: http://gitforwindows.org/)
- cmake (https://cmake.org/download/)

In Linux, you can use repositories to install `git` and `cmake`.

For GPU compilation, it requires Boost libraries as outlined in the [LightGBM R official documentation](https://github.com/Microsoft/LightGBM/tree/master/R-package).

## Usage

It is as simple as this:

```r
lgbdl::lgb.dl(compiler = "vs")
```

For Linux or Rtools/MinGW-only:

```r
lgbdl::lgb.dl(compiler = "gcc")
```

For GPU installation in R:

```r
lgbdl::lgb.dl(compiler = "vs", use_gpu = TRUE)
```

For installing a specific commit of LightGBM:

```r
lgbdl::lgb.dl(commit = "577a03c", compiler = "vs")
```

## Tests

Tested working on:

- Linux + gcc
- Windows + Visual Studio 2015
- Windows + Visual Studio 2017
- Windows + MinGW
