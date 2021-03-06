#' Sensitivity analyses of meta-analysis results
#'
#' Conduct leave-one-out or group-wise sensitivity analyses of meta-analysis
#' results.
#'
#' @param x a `tbl` produced by [meta_analysis()] or by [broom::tidy()]
#' @param type type of sensitvity analysis.
#' @param prefix the prefix for the model result variables, e.g. estimate.
#' @param conf.int logical. Should confidence intervals be included? Default is
#'   `TRUE`.
#' @param exponentiate logical. Should results be exponentiated? Default is
#'   `FALSE`.
#' @param glance logical. Should sensitivity model fit statistics be included?
#'   Default is `FALSE`.
#' @param .f a function for sensitivity analysis. Default is
#'   [metafor::leave1out]
#' @param ... additional arguments
#'
#' @return a `tbl`
#' @export
#'
#' @examples
#'
#' meta_analysis(iud_cxca, yi = lnes, sei = selnes, slab = study_name) %>%
#'   sensitivity()
#'
sensitivity <- function(x, type = "leave1out", prefix = "l1o_",
                        conf.int = TRUE, exponentiate = FALSE, glance = FALSE,
                        .f = metafor::leave1out, ...) {
  if (type == "leave1out") {
    .ma <- pull_meta(x)
    l1out <- .f(.ma) %>%
      as.data.frame() %>%
      tibble::rownames_to_column("study")

    var_names <- c("study", "estimate", "std.error", "statistic", "p.value", "conf.low",
                   "conf.high")

    if (glance) {
        var_names <- c(var_names, "q", "qp", "tau.squared", "i.squared", "h.squared")
        names(l1out) <- paste0(prefix, var_names)
    } else {
        l1out <- dplyr::select(l1out, -Q:-H2)
        names(l1out) <- paste0(prefix, var_names)
      }

  if (exponentiate) {
      l1out[, paste0(prefix, "estimate")] <- exp(l1out[, paste0(prefix, "estimate")])
      l1out[, paste0(prefix, "conf.low")] <- exp(l1out[, paste0(prefix, "conf.low")])
      l1out[, paste0(prefix, "conf.high")] <- exp(l1out[, paste0(prefix, "conf.high")])
  }

  if (!conf.int) {
    l1out <- l1out[-which(names(l1out) %in% paste0(prefix, c("conf.low", "conf.high")))]
  }

  ma_data <- broom::tidy(.ma, conf.int = conf.int, exponentiate = exponentiate,
                         include_studies = FALSE) %>%
    dplyr::select(-type)

  names(ma_data) <- paste0(prefix, names(ma_data))

  dplyr::bind_rows(l1out, ma_data) %>%
    dplyr::left_join(x, ., by = c("study" = paste0(prefix, "study")))

  } else if (type == "group_by") {

  }
}

#' Cumulative sensitivity analyses of meta-analysis results
#'
#' Conduct cumulative sensitivity analyses of meta-analysis results by adding
#' studies in one at a time. `cumulative` works well with [dplyr::arrange()].
#'
#' @param x a `tbl` produced by [meta_analysis()] or by [broom::tidy()]
#' @param prefix the prefix for the model result variables, e.g. estimate.
#' @param conf.int logical. Should confidence intervals be included? Default is
#'   `TRUE`.
#' @param exponentiate logical. Should results be exponentiated? Default is
#'   `FALSE`.
#' @param glance logical. Should sensitivity model fit statistics be included?
#'   Default is `FALSE`.
#' @param .f a function for sensitivity analysis. Default is [metafor::cumul]
#' @param ... additional arguments
#'
#' @return a `tbl`
#' @export
#'
#' @examples
#'
#' library(dplyr)
#'
#' meta_analysis(iud_cxca, yi = lnes, sei = selnes, slab = study_name) %>%
#'   arrange(desc(weight)) %>%
#'   cumulative()
#'
cumulative <- function(x, prefix = "cumul_",
                        conf.int = TRUE, exponentiate = FALSE, glance = FALSE,
                        .f = metafor::cumul, ...) {
  .ma <- pull_meta(x)
  key_df <- data.frame(study = as.character(.ma$slab),
                       .study_order_id = seq_along(.ma$slab),
                       stringsAsFactors = FALSE)
  .study_order_id <- dplyr::left_join(x, key_df, by = "study") %>%
    dplyr::filter(type == "study") %>%
    dplyr::pull(.study_order_id)

  cumul_df <- .f(.ma, order = .study_order_id) %>%
      as.data.frame() %>%
      tibble::rownames_to_column("study")

    var_names <- c("study", "estimate", "std.error", "statistic", "p.value", "conf.low",
                   "conf.high")

    if (glance) {
        var_names <- c(var_names, "q", "qp", "tau.squared", "i.squared", "h.squared")
        names(cumul_df) <- paste0(prefix, var_names)
    } else {
        cumul_df <- dplyr::select(cumul_df, -QE:-H2)
        names(cumul_df) <- paste0(prefix, var_names)
      }

  if (exponentiate) {
      cumul_df[, paste0(prefix, "estimate")] <- exp(cumul_df[, paste0(prefix, "estimate")])
      cumul_df[, paste0(prefix, "conf.low")] <- exp(cumul_df[, paste0(prefix, "conf.low")])
      cumul_df[, paste0(prefix, "conf.high")] <- exp(cumul_df[, paste0(prefix, "conf.high")])
  }

  if (!conf.int) {
    cumul_df <- cumul_df[-which(names(cumul_df) %in% paste0(prefix, c("conf.low", "conf.high")))]
  }

  ma_data <- broom::tidy(.ma, conf.int = conf.int, exponentiate = exponentiate,
                         include_studies = FALSE) %>%
    dplyr::select(-type)

  names(ma_data) <- paste0(prefix, names(ma_data))

  dplyr::bind_rows(cumul_df, ma_data) %>%
    dplyr::left_join(x, ., by = c("study" = paste0(prefix, "study"))) %>%
    dplyr::arrange(type)
}
