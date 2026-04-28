package pt.ipp.estg.elections.api

import io.circe.*
import io.circe.generic.semiauto.*
import pt.ipp.estg.elections.domain.*
import java.util.UUID
import scala.util.Try

/** Codecs JSON da API para requests/responses e tipos de domínio. */
object JsonCodecs:
  /** Conversão segura de UUID a partir de texto recebido no payload. */
  private def parseUuid(value: String): Either[String, UUID] =
    Try(UUID.fromString(value)).toEither.left.map(error => error.getMessage)

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
  /** Payload para mutação de registo de eleitor. */
  final case class RegisterVoterRequest(id: String, fullName: String, electionId: UUID)
  /** Payload para mutação de voto. */
  final case class VoteRequest(voterId: String, electionId: UUID, candidateId: UUID)
  /** Envelope de request GraphQL simplificado usado no projeto. */
  final case class GraphQLRequest(query: String, variables: Option[JsonObject])
  given Decoder[RegisterVoterRequest] = deriveDecoder
  given Decoder[VoteRequest] = deriveDecoder
  given Decoder[GraphQLRequest] = deriveDecoder
  given Encoder[Map[String, Int]] = Encoder.encodeMap[String, Int]
