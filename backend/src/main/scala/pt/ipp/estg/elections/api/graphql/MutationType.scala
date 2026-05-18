package pt.ipp.estg.election.api.graphql

import cats.effect.IO
import pt.ipp.estg.election.api.graphql.schemas.ElectionSchema._
import pt.ipp.estg.election.api.graphql.schemas.IdentitySchema._
import pt.ipp.estg.election.election.domain.{EndDateBeforeStartDate, TitleTooShort}
import pt.ipp.estg.election.identity.domain._
import sangria.schema._

import java.time.Instant
import scala.util.Try

object MutationType {

  val CivilIdArg   = Argument("civilId",   StringType)
  val PasswordArg  = Argument("password",  StringType)
  val TitleArg     = Argument("title",     StringType)
  val StartDateArg = Argument("startDate", StringType)
  val EndDateArg   = Argument("endDate",   StringType)

  val Mutation: ObjectType[ElectionContext, Unit] = ObjectType(
    "Mutation",
    fields[ElectionContext, Unit](

      Field(
        name      = "registerVoter",
        fieldType = RegisterVoterPayloadType,
        arguments = CivilIdArg :: PasswordArg :: Nil,
        resolve   = ctx => {
          val civilId  = ctx.arg(CivilIdArg)
          val password = ctx.arg(PasswordArg)

          ctx.ctx.dispatcher.unsafeToFuture(
            ctx.ctx.registerVoterUseCase.execute(civilId, password).map {
              case Right(voter)               => voter
              case Left(CivilIdAlreadyExists) => RegistrationErrorPayload("O número de identificação civil já está registado.")
              case Left(InvalidCivilIdFormat) => RegistrationErrorPayload("Formato do identificador civil inválido.")
              case Left(WeakPassword)         => RegistrationErrorPayload("A palavra-passe é demasiado fraca.")
            }
          )
        }
      ),

      Field(
        name      = "loginVoter",
        fieldType = LoginVoterPayloadType,
        arguments = CivilIdArg :: PasswordArg :: Nil,
        resolve   = ctx => {
          val civilId  = ctx.arg(CivilIdArg)
          val password = ctx.arg(PasswordArg)
          val ip       = ctx.ctx.requestIp

          ctx.ctx.dispatcher.unsafeToFuture(
            ctx.ctx.loginVoterUseCase.execute(civilId, password, ip).map {
              case Right(token)          => LoginPayload(token.value)
              case Left(VoterNotFound)   => LoginErrorPayload("Eleitor não encontrado.")
              case Left(InvalidPassword) => LoginErrorPayload("Credenciais inválidas.")
            }
          )
        }
      ),

      Field(
        name      = "createElection",
        fieldType = CreateElectionPayloadType,
        arguments = TitleArg :: StartDateArg :: EndDateArg :: Nil,
        resolve   = ctx => {
          val title    = ctx.arg(TitleArg)
          val startStr = ctx.arg(StartDateArg)
          val endStr   = ctx.arg(EndDateArg)

          ctx.ctx.dispatcher.unsafeToFuture(
            IO.fromTry(
              for {
                start <- Try(Instant.parse(startStr))
                end   <- Try(Instant.parse(endStr))
              } yield (start, end)
            ).flatMap { case (start, end) =>
              ctx.ctx.createElectionUseCase.execute(title, start, end).map {
                case Right(election)             => ElectionPayload(election.id.value.toString, election.title.value, election.startDate.toString, election.endDate.toString)
                case Left(EndDateBeforeStartDate) => ElectionErrorPayload("A data de fim deve ser posterior à data de início.")
                case Left(TitleTooShort)          => ElectionErrorPayload("O título da eleição é demasiado curto (mínimo 3 caracteres).")
              }
            }.handleError(_ => ElectionErrorPayload("Formato de data inválido. Use ISO 8601 (ex: 2025-06-01T00:00:00Z)."))
          )
        }
      )
    )
  )
}
