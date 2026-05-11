package pt.ipp.estg.election.api.graphql

import cats.effect.unsafe.implicits.global
import pt.ipp.estg.election.api.graphql.schemas.IdentitySchema._
import sangria.schema._
import pt.ipp.estg.election.identity.domain._

object MutationType {

  val CivilIdArg = Argument("civilId", StringType)
  val PasswordArg = Argument("password", StringType)

  val Mutation: ObjectType[ElectionContext, Unit] = ObjectType(
    "Mutation",
    fields[ElectionContext, Unit](
      Field(
        name = "registerVoter",
        fieldType = RegisterVoterPayloadType,
        arguments = CivilIdArg :: PasswordArg :: Nil,
        resolve = ctx => {
          val civilId = ctx.arg(CivilIdArg)
          val password = ctx.arg(PasswordArg)

          
          val result = ctx.ctx.registerVoterUseCase.execute(civilId, password).unsafeRunSync()

          result match {
            case Right(voter) => voter
            case Left(CivilIdAlreadyExists) => "O número de identificação civil já está registado."
            case Left(InvalidCivilIdFormat) => "Formato do identificador civil inválido."
            case Left(WeakPassword) => "A palavra-passe é demasiado fraca."
          }
        }
      )
    )
  )
}