#' Install LightGBM from source
#'
#' Downloads and install LightGBM from repository. Allows to customize the commit/branch used, the compiler, use a precompiled lib/dll, the link to the repository (if using a custom fork), and the number of cores used (for non-Visual Studio compilations). Requires \code{git} and compiler \code{make} (or \code{mingw32-make} for MinGW) in \code{PATH} environment variable. Windows uses \code{\\\\} (backward slashes) while Linux uses \code{/} (forward slashes) but you can mix them.
#'
#' This installation function supports only Windows (Visual Studio and MinGW) and Linux (gcc and any other compiler making use of \code{make}). Performance of Visual Studio is higher when multithreading is heavy, while MinGW performance is higher when you are using a domestic computer (low number of physical cores, like 2 or 4).
#'
#' Check here for more details: Laurae's \href{https://github.com/Microsoft/LightGBM/issues/542}{Microsoft/LightGBM#542} (Visual Studio reports higher CPU usage than MinGW). and guolinke's \href{https://github.com/Microsoft/LightGBM/pull/584}{Microsoft/LightGBM#584} (Compile R package by custom tool chain).
#'
#' @param commit The commit / branch to use. Put \code{""} for master branch. Defaults to \code{"master"}.
#' @param compiler Applicable only to Windows. The compiler to use (either \code{"gcc"} for MinGW or \code{"vs"} for Visual Studio). Defaults to \code{"gcc"}.
#' @param libdll Applicable only if you use a precompiled dll/lib. The precompiled dll/lib to use. Defaults to \code{""}.
#' @param repo The link to the repository. Defaults to \code{"https://github.com/Microsoft/LightGBM"}.
#' @param use_gpu Whether to install with GPU enabled or not. Defaults to \code{FALSE}.
#' @param cores The number of cores to use for compilation, ignored for Visual Studio. Defaults to \code{1}.
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
#'        repo = "https://github.com/Microsoft/LightGBM")
#'
#' # Install using Rtools MinGW or use Linux compilation
#' lgb.dl(commit = "master",
#'        compiler = "gcc",
#'        repo = "https://github.com/Microsoft/LightGBM",
#'        cores = 2)
#'
#' # Install using precompiled DLL in Windows
#' lgb.dl(commit = "master",
#'        libdll = "C:\\xgboost\\LightGBM\\windows\\x64\\DLL\\lib_lightgbm.dll",
#'        repo = "https://github.com/Microsoft/LightGBM",
#'        cores = 2)
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
                   libdll = "",
                   repo = "https://github.com/Microsoft/LightGBM",
                   use_gpu = FALSE,
                   cores = 1) {

  # Generates temporary dir
  lgb_git_dir <- tempdir()

  # Delete (old) temp LightGBM folder
  unlink(paste0(file.path(lgb_git_dir, "LightGBM")), recursive = TRUE, force = TRUE)

  # Check if it is Windows, because it create most issues
  if (.Platform$OS.type == "windows") {

    # Create temp file
    lgb_git_file <- file.path(lgb_git_dir, "temp.bat", fsep = "\\")

    # Use git to fetch data from repository
    cat(paste0("c:", "\n"), file = lgb_git_file)
    cat(paste0("cd ", lgb_git_dir, "\n"), file = lgb_git_file, append = TRUE)
    cat(paste0("git clone --recursive ", repo, "\n"), file = lgb_git_file, append = TRUE)
    cat(paste0("cd LightGBM", "\n"), file = lgb_git_file, append = TRUE)

    # Checkout specific commit if needed
    if (commit != "") {
      cat(paste0("git checkout ", commit, "\n"), file = lgb_git_file, append = TRUE)
    }

    # Check to move DLL/lib
    if (libdll != "") {
      cat(paste0("cp ", libdll, " ", file.path(lgb_git_dir, "LightGBM", fsep = "\\"), "\n"), file = lgb_git_file, append = TRUE)
    }

  } else {

    # Create temp file
    lgb_git_file <- file.path(lgb_git_dir, "temp.sh")

    # Use git to fetch data from repository
    cat(paste0("cd ", lgb_git_dir, "\n"), file = lgb_git_file)
    cat(paste0("git clone --recursive ", repo, "\n"), file = lgb_git_file, append = TRUE)
    cat(paste0("cd LightGBM", "\n"), file = lgb_git_file, append = TRUE)

    # Checkout specific commit if needed
    if (commit != "") {
      cat(paste0("git checkout ", commit, "\n"), file = lgb_git_file, append = TRUE)
    }

    # Check to move lib
    if (libdll != "") {
      cat(paste0("cp ", libdll, " ", file.path(lgb_git_dir, "LightGBM"), "\n"), file = lgb_git_file, append = TRUE)
    }

    # Set permissions on script
    Sys.chmod(lgb_git_file, mode = "0777", use_umask = TRUE)

  }

  # Do actions
  system(lgb_git_file)

  # Prepare parameter settings
  install_file <- readLines(file.path(lgb_git_dir, "LightGBM", "R-package", "src", "install.libs.R"))

  # Check if compilation must be done using MinGW/gcc (default) or Visual Studio
  if (compiler == "gcc") {
    install_file[4] <- "use_mingw <- TRUE"
  }

  # Check if compilation must allow GPU
  if (use_gpu == TRUE) {
    install_file[3] <- "use_gpu <- TRUE"
  }

  # Check if compilation uses a precompiled DLL/lib
  if (libdll != "") {
    install_file[2] <- "use_precompile <- TRUE"
  }

  # Write parameter settings
  writeLines(install_file, file.path(lgb_git_dir, "LightGBM", "R-package", "src", "install.libs.R"))

  # Make a new temporary folder to work in
  dir.create(file.path(lgb_git_dir, "LightGBM", "lightgbm_r"))

  # copy in the relevant files
  file.copy(from = paste0(file.path(lgb_git_dir, "LightGBM", "R-package"), "/./"),
            to = paste0(file.path(lgb_git_dir, "LightGBM", "lightgbm_r"), "/"),
            recursive = TRUE,
            overwrite = TRUE)

  file.copy(from = paste0(file.path(lgb_git_dir, "LightGBM", "include"), "/"),
            to = paste0(file.path(lgb_git_dir, "LightGBM", "lightgbm_r", "src"), "/"),
            recursive = TRUE,
            overwrite = TRUE)

  file.copy(from = paste0(file.path(lgb_git_dir, "LightGBM", "src"), "/"),
            to = paste0(file.path(lgb_git_dir, "LightGBM", "lightgbm_r", "src"), "/"),
            recursive = TRUE,
            overwrite = TRUE)

  file.copy(from = file.path(lgb_git_dir, "LightGBM", "CMakeLists.txt"),
            to = file.path(lgb_git_dir, "LightGBM", "lightgbm_r", "inst", "bin", "CMakeLists.txt"),
            overwrite = TRUE)

  # devtools::install(pkg = file.path(lgb_git_dir, "LightGBM", "lightgbm_r"),
  #                   args = c("--no-multi-arch"),
  #                   upgrade_dependencies = FALSE)
  # Current installation strategy is below to avoid conflicts
  install.packages(file.path(lgb_git_dir, "LightGBM", "lightgbm_r"), repos = NULL, type = "source")

  # Get rid of the created temporary folder
  unlink(paste0(file.path(lgb_git_dir, "LightGBM")), recursive = TRUE, force = TRUE)

  return(nzchar(system.file(package = "lightgbm")))

}
