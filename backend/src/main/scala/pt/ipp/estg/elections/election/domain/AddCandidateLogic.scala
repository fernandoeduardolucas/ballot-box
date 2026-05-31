package pt.ipp.estg.election.election.domain

import java.time.Instant

object AddCandidateLogic {

  def validate(
    election: Election,
    name:     String,
    party:    Option[String],
    photoUrl: Option[String],
    number:   Int,
    now:      Instant
  ): Either[CandidateError, (CandidateName, Option[String], Option[String], Int)] =
    // The State object decides whether this election still accepts candidates.
    val state = ElectionState.from(election, now)
    for {
      _ <- Either.cond(state.allowsCandidateRegistration, (), ElectionAlreadyStarted: CandidateError)
      _ <- Either.cond(name.trim.length >= 2, (), CandidateNameTooShort: CandidateError)
    } yield (
      CandidateName(name.trim),
      party.map(_.trim).filter(_.nonEmpty),
      photoUrl.map(_.trim).filter(_.nonEmpty),
      number
    )
}
