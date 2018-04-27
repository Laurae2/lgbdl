# LightGBM Online Installer

This is Laurae's LightGBM online installer: it allows to install LightGBM from source directly from your R terminal.

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

R versioning is automatically handled:

* Pre R 3.5 versions are ommitting USE_R35 (`R35` in lgbdl)
* Post (or same as) R 3.5 versions are specifying the USE_R35 (`R35` in lgbdl) flag

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
lgbdl::lgb.dl(commit = "b6db7e2", compiler = "vs")
```

## Tests

Tested working on:

- Visual Studio 2015
- Visual Studio 2017
- MinGW
