% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/project_methods.R
\name{getRDD}
\alias{getRDD}
\title{Get density dependent rate of larvae production}
\usage{
getRDD(
  params,
  n = params@initial_n,
  n_pp = params@initial_n_pp,
  B = params@initial_B,
  sex_ratio = 0.5,
  rdi = getRDI(params, n = n, n_pp = n_pp, B = B, sex_ratio = sex_ratio)
)
}
\arguments{
\item{params}{An \linkS4class{MizerParams} object}

\item{n}{A matrix of species abundances (species x size)}

\item{n_pp}{A vector of the plankton abundance by size}

\item{B}{A vector of biomasses of unstructured resource components}

\item{sex_ratio}{Proportion of the population that is female. Default value
is 0.5.}

\item{rdi}{A vector of density independent recruitment for each species. 
If not specified rdi is calculated internally using
\code{\link{getRDI}}.}
}
\value{
A numeric vector the length of the number of species.
}
\description{
Calculates the density dependent rate of larvae production \eqn{R_i} (units
1/year) for each species. This is the flux entering the smallest size class
of each species. The density dependent rate is the density independent
rate obtained with \code{\link{getRDI}} after it has been put through the 
density dependent "stock-recruitment" relationship function. See
\code{\link{setReproduction}} for more details.
}
\examples{
\dontrun{
data(NS_species_params_gears)
data(inter)
params <- newMultispeciesParams(NS_species_params_gears, inter)
# Project with constant fishing effort for all gears for 20 time steps
sim <- project(params, t_max = 20, effort = 0.5)
# Get the rate at a particular time step
getRDD(params,sim@n[21,,],sim@n_pp[21,])
}
}
\seealso{
\code{\link{getRDI}}

Other rate functions: 
\code{\link{getEGrowth}()},
\code{\link{getEReproAndGrowth}()},
\code{\link{getERepro}()},
\code{\link{getEncounter}()},
\code{\link{getFMortGear}()},
\code{\link{getFMort}()},
\code{\link{getFeedingLevel}()},
\code{\link{getMort}()},
\code{\link{getPlanktonMort}()},
\code{\link{getPredMort}()},
\code{\link{getPredRate}()},
\code{\link{getRDI}()},
\code{\link{getRates}()}
}
\concept{rate functions}
