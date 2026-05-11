package pt.ipp.estg.election.api.graphql.schemas

import pt.ipp.estg.election.identity.domain.Voter
import sangria.schema._
import sangria.macros.derive._

object IdentitySchema {

  val VoterType: ObjectType[Unit, Voter] = ObjectType(
    "Voter",
    "Um eleitor registado no sistema",
    fields[Unit, Voter](
      Field("id", StringType, resolve = _.value.id.value.toString),
      Field("civilId", StringType, resolve = _.value.civilId.value)
    )
  )

  val RegistrationErrorType: ObjectType[Unit, String] = ObjectType(
    "RegistrationError",
    "Erro ocorrido durante o registo",
    fields[Unit, String](
      Field("message", StringType, resolve = _.value)
    )
  )

  val RegisterVoterPayloadType = UnionType(
    "RegisterVoterPayload",
    types = List(VoterType, RegistrationErrorType)
  )
}