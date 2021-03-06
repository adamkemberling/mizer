% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/project_methods.R
\name{getRDI}
\alias{getRDI}
\title{Get density independent rate of egg production}
\usage{
getRDI(
  params,
  n = params@initial_n,
  n_pp = params@initial_n_pp,
  B = params@initial_B,
  e_repro = getERepro(params, n = n, n_pp = n_pp, B = B),
  sex_ratio = 0.5
)
}
\arguments{
\item{params}{An \linkS4class{MizerParams} object}

\item{n}{A matrix of species abundances (species x size)}

\item{n_pp}{A vector of the plankton abundance by size}

\item{B}{A vector of biomasses of unstructured resource components}

\item{e_repro}{The energy available for reproduction (optional). A matrix of
size no. species x no. size bins. If not supplied, is calculated internally
using \code{\link{getERepro}}.}

\item{sex_ratio}{Proportion of the population that is female. Default value
is 0.5.}
}
\value{
A numeric vector the length of the number of species
}
\description{
Calculates the density independent rate of egg production \eqn{R_{p.i}}
(units 1/year) before density dependence, by species. Used by
\code{\link{getRDD}} to calculate the actual density dependent rate.
See \code{\link{setReproduction}} for more details.
}
\examples{
\dontrun{
data(NS_species_params_gears)
data(inter)
params <- newMultispeciesParams(NS_species_params_gears, inter)
# Project with constant fishing effort for all gears for 20 time steps
sim <- project(params, t_max = 20, effort = 0.5)
# Get the recruitment at a particular time step
getRDI(params,sim@n[21,,],sim@n_pp[21,])
}
}
\seealso{
\code{\link{getRDD}}

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
\code{\link{getRDD}()},
\code{\link{getRates}()}
}
\concept{rate functions}
