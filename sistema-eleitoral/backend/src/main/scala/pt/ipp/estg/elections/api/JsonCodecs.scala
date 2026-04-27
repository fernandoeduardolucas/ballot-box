package pt.ipp.estg.elections.api

import io.circe.*
import io.circe.generic.semiauto.*
import pt.ipp.estg.elections.domain.*
import java.util.UUID

object JsonCodecs:
  given Encoder[ElectionId] = Encoder.encodeString.contramap(_.value.toString)
  given Decoder[ElectionId] = Decoder.decodeString.emap(s => Either.catchNonFatal(ElectionId(UUID.fromString(s))).left.map(_.getMessage))
  given Encoder[CandidateId] = Encoder.encodeString.contramap(_.value.toString)
  given Decoder[CandidateId] = Decoder.decodeString.emap(s => Either.catchNonFatal(CandidateId(UUID.fromString(s))).left.map(_.getMessage))
  given Encoder[VoterId] = Encoder.encodeString.contramap(_.value)
  given Decoder[VoterId] = Decoder.decodeString.map(VoterId.apply)
  given Encoder[Candidate] = deriveEncoder
  given Decoder[Candidate] = deriveDecoder
  given Encoder[Election] = deriveEncoder
  given Decoder[Election] = deriveDecoder
  final case class RegisterVoterRequest(id: String, fullName: String, electionId: UUID)
  final case class VoteRequest(voterId: String, electionId: UUID, candidateId: UUID)
  given Decoder[RegisterVoterRequest] = deriveDecoder
  given Decoder[VoteRequest] = deriveDecoder
  given Encoder[Map[String, Int]] = Encoder.encodeMap[String, Int]
