# Inventory data


#' Raw inventory table.
#'
#' @return A `data.frame` or `tibble`. Call \code{\link{fd_metadata}} for field metadata.#'
#' @export
#' @author Measurements by Gough Lab at the University of Michigan Biological Station.
#' @examples
#' fd_inventory()
fd_inventory <- function() {
  inv <- read_csv_file("forte_inventory.csv")
  inv$date <- as.Date(inv$date, format = "%m/%d/%Y")

  inv <- split_subplot_id(inv)

  # Currently there's a bad entry in the table. Nuke it. Temporary
  inv$dbh_cm <- as.numeric(inv$dbh_cm)  # temporary, until we fix row 791

  inv <- inv[c("subplot_id", "replicate", "plot", "subplot","date","tag", "species", "dbh_cm", "health_status", "canopy_status", "notes")]

  weak_as_tibble(inv)
}

#' Basic statistics generated from the raw inventory data.
#'
#' @details The returned columns are as follows:
#' - `replicate` (character): Replicate code, extracted from `SubplotID`.
#' - `plot` (integer): Plot ID number, extracted from `SubplotID`.
#' - `subplot` (character): Subplot code, extracted from `SubplotID`.
#' - `ba_m2_ha` (numeric): Basal area, square meters per hectare.
#' - `stocking_ha` (numeric): Stocking, trees per hectare.
#'
#' @return A `data.frame` or `tibble`. See "Details" for column descriptions.
#' @note For now this is pretty basic. More detailed summaries could be made,
#' e.g. by live/dead, species, etc.
#' @export
#' @importFrom stats aggregate
#' @author Measurements by Gough Lab at the University of Michigan Biological Station.
#' @examples
#' fd_inventory_summary()
fd_inventory_summary <- function() {
  # Load the inventory and subplot tables and merge them
  subplots <- fd_subplots()[c("replicate", "plot", "subplot", "subplot_area_m2")]
  inv <- merge(fd_inventory(), subplots)

  # Subset and compute basal area and stocking
  inv <- inv[inv$health_status != "D",]  # non-dead trees only
  message("Live and moribund trees only")

  hectare_area <- 10000 # m2
  # radius[cm] => DBH[cm] / 2
  # radius[m] => radius[cm] / 100
  # area[ha] => area[m2] / hectare_area
  # basal_area[m2 ha-1] => (pi * radius[m]^2) * (1 / area[ha])
  inv$ba_m2_ha <- pi * (inv$dbh_cm / 100 / 2) ^ 2 * hectare_area / inv$subplot_area_m2
  inv$stocking_ha <- hectare_area / inv$subplot_area_m2
  stocking <- aggregate(stocking_ha ~ replicate + plot + subplot , data = inv, FUN = sum)
  ba <- aggregate(ba_m2_ha ~ replicate + plot + subplot, data = inv, FUN = sum)

  #ba$Stocking <- stocking$DBH_cm
  weak_as_tibble(merge(ba, stocking))
}
