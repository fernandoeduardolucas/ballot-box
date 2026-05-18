package pt.ipp.estg.election.election.domain

import java.time.Instant
import java.util.UUID

case class ElectionId(value: UUID)    extends AnyVal
case class ElectionTitle(value: String) extends AnyVal

case class Election(
  id:        ElectionId,
  title:     ElectionTitle,
  startDate: Instant,
  endDate:   Instant
)

object Election {
  def validate(
    title:     String,
    startDate: Instant,
    endDate:   Instant
  ): Either[ElectionError, (ElectionTitle, Instant, Instant)] =
    for {
      _ <- Either.cond(title.trim.length >= 3, (), TitleTooShort: ElectionError)
      _ <- Either.cond(endDate.isAfter(startDate), (), EndDateBeforeStartDate: ElectionError)
    } yield (ElectionTitle(title.trim), startDate, endDate)
}
