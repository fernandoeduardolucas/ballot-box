package pt.ipp.estg.election.api.graphql.schemas

import sangria.schema._

object ElectionSchema {

  // ─── Election ───────────────────────────────────────────────────────────────

  case class ElectionPayload(id: String, title: String, startDate: String, endDate: String)
  case class ElectionErrorPayload(message: String)

  val ElectionPayloadType: ObjectType[Unit, ElectionPayload] = ObjectType(
    "ElectionPayload",
    "Eleição criada com sucesso",
    fields[Unit, ElectionPayload](
      Field("id",        StringType, resolve = _.value.id),
      Field("title",     StringType, resolve = _.value.title),
      Field("startDate", StringType, resolve = _.value.startDate),
      Field("endDate",   StringType, resolve = _.value.endDate)
    )
  )

  val ElectionErrorPayloadType: ObjectType[Unit, ElectionErrorPayload] = ObjectType(
    "ElectionError",
    "Erro ocorrido durante a criação da eleição",
    fields[Unit, ElectionErrorPayload](
      Field("message", StringType, resolve = _.value.message)
    )
  )

  val CreateElectionPayloadType: UnionType[Unit] = UnionType(
    "CreateElectionPayload",
    types = List(ElectionPayloadType, ElectionErrorPayloadType)
  )

  // ─── Candidate ──────────────────────────────────────────────────────────────

  case class CandidatePayload(
    id:         String,
    electionId: String,
    name:       String,
    party:      Option[String],
    photoUrl:   Option[String],
    number:     Int
  )
  case class CandidateErrorPayload(message: String)

  val CandidatePayloadType: ObjectType[Unit, CandidatePayload] = ObjectType(
    "CandidatePayload",
    "Candidato adicionado com sucesso",
    fields[Unit, CandidatePayload](
      Field("id",         StringType,             resolve = _.value.id),
      Field("electionId", StringType,             resolve = _.value.electionId),
      Field("name",       StringType,             resolve = _.value.name),
      Field("party",      OptionType(StringType), resolve = _.value.party),
      Field("photoUrl",   OptionType(StringType), resolve = _.value.photoUrl),
      Field("number",     IntType,                resolve = _.value.number)
    )
  )

  val CandidateErrorPayloadType: ObjectType[Unit, CandidateErrorPayload] = ObjectType(
    "CandidateError",
    "Erro ao adicionar candidato",
    fields[Unit, CandidateErrorPayload](
      Field("message", StringType, resolve = _.value.message)
    )
  )

  val AddCandidatePayloadType: UnionType[Unit] = UnionType(
    "AddCandidatePayload",
    types = List(CandidatePayloadType, CandidateErrorPayloadType)
  )

  // ─── Vote (cast) ─────────────────────────────────────────────────────────────

  case class CastVotePayload(voteId: String, electionId: String, votedAt: String)
  case class CastVoteErrorPayload(message: String)

  val CastVoteSuccessPayloadType: ObjectType[Unit, CastVotePayload] = ObjectType(
    "CastVoteSuccess",
    "Voto submetido com sucesso",
    fields[Unit, CastVotePayload](
      Field("voteId",     StringType, resolve = _.value.voteId),
      Field("electionId", StringType, resolve = _.value.electionId),
      Field("votedAt",    StringType, resolve = _.value.votedAt)
    )
  )

  val CastVoteErrorPayloadType: ObjectType[Unit, CastVoteErrorPayload] = ObjectType(
    "CastVoteError",
    "Erro ao submeter voto",
    fields[Unit, CastVoteErrorPayload](
      Field("message", StringType, resolve = _.value.message)
    )
  )

  val CastVotePayloadType: UnionType[Unit] = UnionType(
    "CastVotePayload",
    types = List(CastVoteSuccessPayloadType, CastVoteErrorPayloadType)
  )

  // ─── Vote Results ────────────────────────────────────────────────────────────

  case class VoteCountPayload(candidateId: String, candidateName: String, count: Long)

  val VoteCountPayloadType: ObjectType[Unit, VoteCountPayload] = ObjectType(
    "VoteCountPayload",
    "Contagem de votos por candidato",
    fields[Unit, VoteCountPayload](
      Field("candidateId",   StringType, resolve = _.value.candidateId),
      Field("candidateName", StringType, resolve = _.value.candidateName),
      Field("count",         LongType,   resolve = _.value.count)
    )
  )
}
