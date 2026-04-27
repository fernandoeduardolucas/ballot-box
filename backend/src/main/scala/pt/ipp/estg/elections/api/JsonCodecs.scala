package pt.ipp.estg.elections.api

import io.circe.*
import io.circe.generic.semiauto.*
import pt.ipp.estg.elections.domain.*
import java.util.UUID

object JsonCodecs:
  private def parseUuid(value: String): Either[String, UUID] =
    Either.catchNonFatal(UUID.fromString(value)).left.map(error => error.getMessage)

  given Encoder[ElectionId] = Encoder.encodeString.contramap(electionId => electionId.value.toString)
  given Decoder[ElectionId] = Decoder.decodeString.emap { rawValue =>
    parseUuid(rawValue).map(uuid => ElectionId(uuid))
  }
  given Encoder[CandidateId] = Encoder.encodeString.contramap(candidateId => candidateId.value.toString)
  given Decoder[CandidateId] = Decoder.decodeString.emap { rawValue =>
    parseUuid(rawValue).map(uuid => CandidateId(uuid))
  }
  given Encoder[VoterId] = Encoder.encodeString.contramap(voterId => voterId.value)
  given Decoder[VoterId] = Decoder.decodeString.map(VoterId.apply)
  given Encoder[Candidate] = deriveEncoder
  given Decoder[Candidate] = deriveDecoder
  given Encoder[Election] = deriveEncoder
  given Decoder[Election] = deriveDecoder
  final case class RegisterVoterRequest(id: String, fullName: String, electionId: UUID)
  final case class VoteRequest(voterId: String, electionId: UUID, candidateId: UUID)
  final case class GraphQLRequest(query: String, variables: Option[JsonObject])
  given Decoder[RegisterVoterRequest] = deriveDecoder
  given Decoder[VoteRequest] = deriveDecoder
  given Decoder[GraphQLRequest] = deriveDecoder
  given Encoder[Map[String, Int]] = Encoder.encodeMap[String, Int]
