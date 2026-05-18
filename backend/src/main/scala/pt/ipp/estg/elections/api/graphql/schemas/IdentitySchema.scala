package pt.ipp.estg.election.api.graphql.schemas

import pt.ipp.estg.election.identity.domain.Voter
import sangria.schema._

object IdentitySchema {

  case class RegistrationErrorPayload(message: String)
  case class LoginPayload(token: String, isAdmin: Boolean)
  case class LoginErrorPayload(message: String)

  val VoterType: ObjectType[Unit, Voter] = ObjectType(
    "Voter",
    "Um eleitor registado no sistema",
    fields[Unit, Voter](
      Field("id",      StringType, resolve = _.value.id.value.toString),
      Field("civilId", StringType, resolve = _.value.civilId.value)
    )
  )

  val RegistrationErrorPayloadType: ObjectType[Unit, RegistrationErrorPayload] = ObjectType(
    "RegistrationError",
    "Erro ocorrido durante o registo",
    fields[Unit, RegistrationErrorPayload](
      Field("message", StringType, resolve = _.value.message)
    )
  )

  val RegisterVoterPayloadType: UnionType[Unit] = UnionType(
    "RegisterVoterPayload",
    types = List(VoterType, RegistrationErrorPayloadType)
  )

  val LoginPayloadType: ObjectType[Unit, LoginPayload] = ObjectType(
    "LoginPayload",
    "Token JWT gerado após autenticação bem-sucedida",
    fields[Unit, LoginPayload](
      Field("token",   StringType,  resolve = _.value.token),
      Field("isAdmin", BooleanType, resolve = _.value.isAdmin)
    )
  )

  val LoginErrorPayloadType: ObjectType[Unit, LoginErrorPayload] = ObjectType(
    "LoginError",
    "Erro ocorrido durante a autenticação",
    fields[Unit, LoginErrorPayload](
      Field("message", StringType, resolve = _.value.message)
    )
  )

  val LoginVoterPayloadType: UnionType[Unit] = UnionType(
    "LoginVoterPayload",
    types = List(LoginPayloadType, LoginErrorPayloadType)
  )
}
