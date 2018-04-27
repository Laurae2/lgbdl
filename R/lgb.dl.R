#' Install LightGBM from source
#'
#' Downloads and install LightGBM from repository. Allows to customize the commit/branch used, the compiler, using a precompiled lib/dll, the link to the repository (if using a custom fork), and the number of cores used (for non-Visual Studio compilations). Requires \code{git} and compiler \code{make} (or \code{mingw32-make} for MinGW) in \code{PATH} environment variable. Windows uses \code{\\\\} (backward slashes) while Linux uses \code{/} (forward slashes).
#'
#' This installation function supports only Windows (Visual Studio and MinGW) and Linux (gcc and any other compiler making use of \code{make}). Performance of Visual Studio is higher when multithreading is heavy, while MinGW performance is higher when you are using a domestic computer (low number of physical cores, like 2 or 4).
#'
#' Check here for more details: Laurae's \href{https://github.com/Microsoft/LightGBM/issues/542}{Microsoft/LightGBM#542} (Visual Studio reports higher CPU usage than MinGW). and guolinke's \href{https://github.com/Microsoft/LightGBM/pull/584}{Microsoft/LightGBM#584} (Compile R package by custom tool chain).
#'
#' @param commit The commit / branch to use. Put \code{""} for master branch. Defaults to \code{"master"}.
#' @param compiler Applicable only to Windows. The compiler to use (either \code{"gcc"} for MinGW or \code{"vs"} for Visual Studio). Defaults to \code{"gcc"}.
# @param devenv Applicable only to Windows and Visual Studio. The path to \code{devenv} of the appropriate Visual Studio compiler. Defaults to \code{"C:\\Program Files (x86)\\Microsoft Visual Studio\\Preview\\Community\\Common7\\IDE"}
# @param msbuild Applicable only to Windows and Visual Studio. The path to \code{msbuild} of the appropriate Visual Studio compiler. Defaults to \code{"C:\\Program Files (x86)\\Microsoft Visual Studio\\Preview\\Community\\MSBuild\\15.0\\Bin"}
#' @param libdll Applicable only if you use a precompiled dll/lib. The precompiled dll/lib to use. Defaults to \code{""}.
#' @param repo The link to the repository. Defaults to \code{"https://github.com/Microsoft/LightGBM"}.
#' @param use_gpu Whether to install with GPU enabled or not. Cannot use \code{libdll} if \code{use_gpu} is \code{TRUE}. Defaults to \code{FALSE}.
#' @param cores The number of cores to use for compilation, ignored for Visual Studio. Defaults to \code{1}.
#' @param R35 Whether to compile or not for R version 3.5 and later. If you use R 3.5 or later, please set this to \code{TRUE}. Defaults to \code{((as.numeric(R.Version()$major) == 3) & (as.numeric(R.Version()$minor) >= 5)) | (as.numeric(R.Version()$major) > 3)}, which means attempt to automatically find the version and use the correct flag.
#'
#' @return A logical describing whether the LightGBM package was installed or not (\code{TRUE} if installed, \code{FALSE} if installation failed AND you did not have the package before).
#'
#' @importFrom utils install.packages
#'
#' @examples
#' \dontrun{
#' # Install using Visual Studio
#' # (Download: http://landinghub.visualstudio.com/visual-cpp-build-tools)
#' lgb.dl(commit = "master",
#'        compiler = "vs",
#'        repo = "https://github.com/Microsoft/LightGBM",
#'        cores = 4)
#'
#' # Install using Rtools MinGW or use Linux compilation
#' lgb.dl(commit = "master",
#'        compiler = "gcc",
#'        repo = "https://github.com/Microsoft/LightGBM",
#'        cores = 4)
#'
#' # Install using precompiled DLL in Windows
#' lgb.dl(commit = "master",
#'        libdll = "C:\\xgboost\\LightGBM\\windows\\x64\\DLL\\lib_lightgbm.dll",
#'        repo = "https://github.com/Microsoft/LightGBM",
#'        cores = 4)
#'
#' # Test package
#' library(lightgbm)
#' data(agaricus.train, package = "lightgbm")
#' train <- agaricus.train
#' dtrain <- lgb.Dataset(train$data, label = train$label)
#' data(agaricus.test, package = "lightgbm")
#' test <- agaricus.test
#' dtest <- lgb.Dataset.create.valid(dtrain, test$data, label = test$label)
#' params <- list(objective = "regression", metric = "l2")
#' valids <- list(test = dtest)
#' model <- lgb.train(params,
#'                    dtrain,
#'                    100,
#'                    valids,
#'                    min_data = 1,
#'                    learning_rate = 1,
#'                    early_stopping_rounds = 10)
#' }
#'
#' @export

lgb.dl <- function(commit = "master",
                   compiler = "gcc",
                   #devenv = "C:\\Program Files (x86)\\Microsoft Visual Studio\\Preview\\Community\\Common7\\IDE",
                   #msbuild = "C:\\Program Files (x86)\\Microsoft Visual Studio\\Preview\\Community\\MSBuild\\15.0\\Bin",
                   libdll = "",
                   repo = "https://github.com/Microsoft/LightGBM",
                   use_gpu = FALSE,
                   cores = 1,
                   R35 = ((as.numeric(R.Version()$major) == 3) & (as.numeric(R.Version()$minor) >= 5)) | (as.numeric(R.Version()$major) > 3)) {

  # Generates temporary dir
  lgb_git_dir <- tempdir()

  # Check if it is Windows, because it create most issues
  if (.Platform$OS.type == "windows") {

    # Create temp file
    lgb_git_file <- file.path(lgb_git_dir, "temp.bat", fsep = "\\")

    # Delete (old) temp LightGBM folder
    unlink(paste0(file.path(lgb_git_dir, "LightGBM", fsep = "\\")), recursive = TRUE, force = TRUE)

    # Use git to fetch data from repository
    cat(paste0("c:", "\n"), file = lgb_git_file)
    cat(paste0("cd ", lgb_git_dir, "\n"), file = lgb_git_file, append = TRUE)
    cat(paste0("git clone --recursive ", repo, "\n"), file = lgb_git_file, append = TRUE)
    cat(paste0("cd LightGBM", "\n"), file = lgb_git_file, append = TRUE)

    # Checkout specific commit if needed
    if (commit != "") {
      cat(paste0("git checkout ", commit, "\n"), file = lgb_git_file, append = TRUE)
    }

    # If no lib is specified, force compilation
    if (libdll == "") {

      # Check if compilation must be done using MinGW/gcc (default) or Visual Studio
      if (compiler == "gcc") {

        cat(paste0("mkdir build && cd build", "\n"), file = lgb_git_file, append = TRUE)
        cat(paste0("cmake -G \"MinGW Makefiles\" ", ifelse(R35 == TRUE, "-DUSE_R35=1 ", ""), ifelse(use_gpu == TRUE, "-DUSE_GPU=1", ""), " ..", "\n"), file = lgb_git_file, append = TRUE)
        cat(paste0("cmake -G \"MinGW Makefiles\" ", ifelse(R35 == TRUE, "-DUSE_R35=1 ", ""), ifelse(use_gpu == TRUE, "-DUSE_GPU=1", ""), " ..", "\n"), file = lgb_git_file, append = TRUE) # Failsafe as R has .sh
        cat(paste0("mingw32-make.exe -j", cores, "\n"), file = lgb_git_file, append = TRUE)

      } else {

        cat(paste0("mkdir build && cd build", "\n"), file = lgb_git_file, append = TRUE)
        cat(paste0("cmake -DCMAKE_GENERATOR_PLATFORM=x64 ", ifelse(R35 == TRUE, "-DUSE_R35=1 ", ""), ifelse(use_gpu == TRUE, "-DUSE_GPU=1", ""), " ..", "\n"), file = lgb_git_file, append = TRUE)
        cat(paste0("cmake --build . --target _lightgbm  --config Release", "\n"), file = lgb_git_file, append = TRUE)

      }

    } else {

      cat(paste0("cp ", libdll, " ", file.path(lgb_git_dir, "LightGBM", fsep = "\\"), "\n"), file = lgb_git_file, append = TRUE) # Move dll/lib

    }

    # Do actions
    system(lgb_git_file)

    # Strange workaround to rename stuff
    file.rename(from = file.path(lgb_git_dir, "LightGBM", "R-package", "src", "install.libs.R", fsep = "\\"), to = file.path(lgb_git_dir, "LightGBM", "R-package", "src", "install.libs2.R", fsep = "\\"))
    cat(gsub("use_precompile <- FALSE", "use_precompile <- TRUE", readLines(file.path(lgb_git_dir, "LightGBM", "R-package", "src", "install.libs2.R", fsep = "\\"))), file = file.path(lgb_git_dir, "LightGBM", "R-package", "src", "install.libs.R", fsep = "\\"), sep = "\n")

    # Install package
    install.packages(file.path(lgb_git_dir, "LightGBM", "R-package", fsep = "\\"), repos = NULL, type = "source")

    # Get rid of the created temporary folder
    unlink(paste0(file.path(lgb_git_dir, "LightGBM", fsep = "\\")), recursive = TRUE, force = TRUE)

  } else {

    # Create temp file
    lgb_git_file <- file.path(lgb_git_dir, "temp.sh")

    # Delete (old) temp LightGBM folder
    unlink(paste0(file.path(lgb_git_dir, "LightGBM")), recursive = TRUE, force = TRUE)

    # Use git to fetch data from repository
    cat(paste0("cd ", lgb_git_dir, "\n"), file = lgb_git_file)
    cat(paste0("git clone --recursive ", repo, "\n"), file = lgb_git_file, append = TRUE)
    cat(paste0("cd LightGBM", "\n"), file = lgb_git_file, append = TRUE)

    # Checkout specific commit if needed
    if (commit != "") {
      cat(paste0("git checkout ", commit, "\n"), file = lgb_git_file, append = TRUE)
    }

    # If no lib is specified, force compilation
    if (libdll == "") {
      cat(paste0("mkdir build && cd build", "\n"), file = lgb_git_file, append = TRUE)
      cat(paste0("cmake ", ifelse(R35 == TRUE, "-DUSE_R35=1 ", ""), ifelse(use_gpu == TRUE, "-DUSE_GPU=1", ""), " ..", "\n"), file = lgb_git_file, append = TRUE)
      cat(paste0("cmake ", ifelse(R35 == TRUE, "-DUSE_R35=1 ", ""), ifelse(use_gpu == TRUE, "-DUSE_GPU=1", ""), " ..", "\n"), file = lgb_git_file, append = TRUE) # Failsafe as R has .sh
      cat(paste0("make -j", cores), file = lgb_git_file, append = TRUE)
    } else {
      cat(paste0("cp ", libdll, " ", file.path(lgb_git_dir, "LightGBM"), "\n"), file = lgb_git_file, append = TRUE) # Move dll/lib
    }

    # Set permissions on script
    Sys.chmod(lgb_git_file, mode = "0777", use_umask = TRUE)

    # Do actions
    system(lgb_git_file)

    # Strange workaround to rename stuff
    file.rename(from = file.path(lgb_git_dir, "LightGBM", "R-package", "src", "install.libs.R"), to = file.path(lgb_git_dir, "LightGBM", "R-package", "src", "install.libs2.R"))
    cat(gsub("use_precompile <- FALSE", "use_precompile <- TRUE", readLines(file.path(lgb_git_dir, "LightGBM", "R-package", "src", "install.libs2.R"))), file = file.path(lgb_git_dir, "LightGBM", "R-package", "src", "install.libs.R"), sep = "\n")

    # Install package
    install.packages(file.path(lgb_git_dir, "LightGBM", "R-package"), repos = NULL, type = "source")

    # Get rid of the created temporary folder
    unlink(paste0(file.path(lgb_git_dir, "LightGBM")), recursive = TRUE, force = TRUE)

  }

  return(nzchar(system.file(package = "lightgbm")))

}
