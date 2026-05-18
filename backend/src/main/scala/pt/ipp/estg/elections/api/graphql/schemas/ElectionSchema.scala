package pt.ipp.estg.election.api.graphql.schemas

import sangria.schema._

object ElectionSchema {

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
}
