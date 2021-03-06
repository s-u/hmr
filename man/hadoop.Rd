\name{hadoop}
\alias{hadoop}
\alias{hmr}
\alias{hinput}
\alias{hpath}
\alias{c.hinput}
\alias{open.HDFSpath}
\alias{print.HDFSpath}
\title{
  Experimental Hadoop chunk-processing code
}
\description{
  \code{hmr} runs a chunk-wise Hadoop job.

  \code{hpath} and \code{hinput} define HDFS file path and input source.
}
\usage{
hmr(input, output, map = identity, reduce = identity, job.name,
    aux, formatter, packages = loadedNamespaces(), reducers,
    wait=TRUE, hadoop.conf, hadoop.opt, R="R",
    verbose = TRUE, persistent = FALSE, overwrite = FALSE,
    use.kinit = !is.null(getOption("hmr.kerberos.realm")))
hpath(path)
hinput(path, formatter = .default.formatter)
}
\arguments{
  \item{input}{input data - see details}
  \item{output}{output path (optional)}
  \item{map}{chunk compute function (map is a misnomer)}
  \item{reduce}{chunk combine function}
  \item{job.name}{name of the job to pass to Hadoop}
  \item{aux}{either a character vector of symbols names or a named list
    of values to push to the compute nodes}
  \item{formatter}{formatter to use. It is optional in \code{hmr} if the
    input source already contains a formatter definition. See below for
    details on how to sepcify separate formatters.}
  \item{packages}{character vector of package names to attach on the
    compute nodes}
  \item{reducers}{optional integer specifying the number of parallel
    jobs in the combine step. It is a hint in the sense that any number
    greater than one implies independence of the chunks in the combine
    step. Default is to not assume independence.}
  \item{wait}{logical, if \code{TRUE} then the command returns after the
    job finished, otherwise the command returns after the job has been
    submitted}
  \item{hadoop.conf}{optional string, path to the hadoop configuration
    directory for submission}
  \item{hadoop.opt}{additional Java options to pass to the job - named
    character vectors are passed as \code{-D<name>=<value>}, unnamed
    vectors are collapsed. Note: this is only a transitional interface
    to work around deficiencies in the job generation and should only be
    used as a last measure since the semantics is implementation
    specific and thus not prtable across systems.}
  \item{R}{command to call to run R on the Hadoop cluster}
  \item{verbose}{logical, indicating whether the output sent to standard
    error and standard out from hadoop should be printed to the console.}
  \item{persistent}{logical, if \code{TRUE} then an ROctopus job is
    started and the mapper is executed in "hot" ROctopus instances
    instead of regular R. The results in that case are ROctopus URLs.}
  \item{overwrite}{logical, if \code{TRUE} then the output directory
    is first deleted before the job is started.}
  \item{use.kinit}{logical, if \code{TRUE} automatically invokes
    \code{\link[krb5]{kinit}(realm=getOption("hmr.kerberos.realm"))} before
    running any Hadoop commands.}
  \item{path}{HDFS path}
}
\details{
  \code{hmr} creates and runs a Hadoop job to perform chunkwise compute
  + combine. The input is read using \code{\link{chunk.reader}},
  processed using the \code{formatter} function and passed to the
  \code{map} function. The result is converted using \code{as.output}
  before going back to Hadoop. The chunkwise results are combined using
  the \code{reduce} function - the flow is the same as in the \code{map}
  case. Then result is returned as HDFS path. Either \code{map} or
  \code{reduce} can be \code{identity} (the default).

  If the \code{formatter} if omitted then the format is taken from
  input object (if it has one) or the default formatter
  (\code{mstrsplit} with \code{'\t'} as key spearator, \code{'|'} as
  column separator) is used. If formater is a function then the same
  formatter is used for both the map and reduce steps. If separate
  formatters are required, the \code{formatter} can be a list with the
  entries \code{map} and/or \code{reduce} specifying the corresponding
  formatter function.

  \code{hpath} tags a string as HDFS path. The sole purpose here is to
  distiguish local and HDFS paths.

  \code{hinput} creates a subclass of \code{HDFSpath} which also
  contains the definition of the formatter for that path. The default
  formatter honors default Hadoop settings of \code{'\t'} as the
  key/value separator and \code{'|'} as the field separator.
}
\value{
  \code{hmr} returns the HDFS path to the result when finished.

  \code{hpath} returns a character vector of class \code{"HDFSpath"}

  \code{hinput} returns a subclass \code{"hinput"} of \code{"HDFSpath"}
  containing the additional \code{"formatter"} attribute.
}
\note{
  Requires properly installed Hadoop client. The installation must
  either be in \code{/usr/lib/hadoop} or one of \code{HADOOP_HOME},
  \code{HADOOP_PREFIX} environment variables must be set accordingly.
}
\author{
  Simon Urbanek
}
\examples{
\dontrun{
## map points to ZIP codes and count the number of points per ZIP
## uses Tiger/LINE 2010 census data shapefiles
## we can use ctapply becasue Hadoop guarantees contiguous input

## require(fastshp); require(tl2010)
r <- hmr(
  hinput("/data/points"),
  map = function(x)
    table(zcta2010.db()[
       inside(zcta2010.shp(), x[,4], x[,5]), 1]),
  reduce = function(x) ctapply(as.numeric(x), names(x), sum))
}
}
\keyword{manip}
