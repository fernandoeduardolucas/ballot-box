package pt.ipp.estg.election.election.domain

import pt.ipp.estg.election.identity.domain.Nut3Region
import java.time.Instant
import java.util.UUID

case class ElectionId(value: UUID)    extends AnyVal
case class ElectionTitle(value: String) extends AnyVal

enum ElectionScope:
  case National
  case Regional(region: Nut3Region)

object ElectionScope:
  def fromRegionCode(regionCode: Option[String]): Option[ElectionScope] =
    regionCode match
      case None       => Some(ElectionScope.National)
      case Some(code) => Nut3Region.fromCode(code).map(region => ElectionScope.Regional(region))

  def regionCode(scope: ElectionScope): Option[String] =
    scope match
      case ElectionScope.National         => None
      case ElectionScope.Regional(region) => Some(region.code)

  def label(scope: ElectionScope): String =
    scope match
      case ElectionScope.National => "Nacional"
      case ElectionScope.Regional(Nut3Region.AreaMetropolitanaPorto) => "Porto"
      case ElectionScope.Regional(Nut3Region.AreaMetropolitanaLisboa) => "Lisboa"
      case ElectionScope.Regional(region) => region.label

case class Election(
  id:        ElectionId,
  title:     ElectionTitle,
  startDate: Instant,
  endDate:   Instant,
  scope:     ElectionScope = ElectionScope.National
)

object Election {
  def validate(
    title:           String,
    startDate:       Instant,
    endDate:         Instant,
    scopeRegionCode: Option[String] = None
  ): Either[ElectionError, (ElectionTitle, Instant, Instant, ElectionScope)] =
    for {
      _     <- Either.cond(title.trim.length >= 3, (), TitleTooShort: ElectionError)
      _     <- Either.cond(endDate.isAfter(startDate), (), EndDateBeforeStartDate: ElectionError)
      scope <- ElectionScope.fromRegionCode(scopeRegionCode).toRight(InvalidElectionScope: ElectionError)
    } yield (ElectionTitle(title.trim), startDate, endDate, scope)
}
