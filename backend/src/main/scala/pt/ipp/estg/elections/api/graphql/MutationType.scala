package pt.ipp.estg.election.api.graphql

import cats.effect.IO
import pt.ipp.estg.election.api.graphql.schemas.ElectionSchema._
import pt.ipp.estg.election.api.graphql.schemas.IdentitySchema._
import pt.ipp.estg.election.election.domain.{CandidateNameTooShort, ElectionAlreadyStarted, ElectionNotFound, EndDateBeforeStartDate, TitleTooShort}
import pt.ipp.estg.election.identity.domain._
import sangria.schema._

import java.time.Instant
import java.util.UUID
import scala.concurrent.Future
import scala.util.Try

object MutationType {

  val CivilIdArg    = Argument("civilId",    StringType)
  val PasswordArg   = Argument("password",   StringType)
  val Nut3RegionArg = Argument("nut3Region", StringType)
  val TitleArg      = Argument("title",      StringType)
  val StartDateArg  = Argument("startDate",  StringType)
  val EndDateArg    = Argument("endDate",    StringType)
  val ElectionIdArg = Argument("electionId", StringType)
  val NameArg       = Argument("name",       StringType)
  val PartyArg      = Argument("party",      OptionInputType(StringType))
  val PhotoUrlArg   = Argument("photoUrl",   OptionInputType(StringType))
  val NumberArg     = Argument("number",     IntType)

  val Mutation: ObjectType[ElectionContext, Unit] = ObjectType(
    "Mutation",
    fields[ElectionContext, Unit](

      Field(
        name      = "registerVoter",
        fieldType = RegisterVoterPayloadType,
        arguments = CivilIdArg :: PasswordArg :: Nut3RegionArg :: Nil,
        resolve   = ctx => {
          val civilId   = ctx.arg(CivilIdArg)
          val password  = ctx.arg(PasswordArg)
          val nut3Code  = ctx.arg(Nut3RegionArg)

          ctx.ctx.dispatcher.unsafeToFuture(
            ctx.ctx.registerVoterUseCase.execute(civilId, password, nut3Code).map {
              case Right(voter)               => voter
              case Left(CivilIdAlreadyExists) => RegistrationErrorPayload("O número de identificação civil já está registado.")
              case Left(InvalidCivilIdFormat) => RegistrationErrorPayload("Formato do identificador civil inválido.")
              case Left(WeakPassword)         => RegistrationErrorPayload("A palavra-passe é demasiado fraca.")
              case Left(InvalidNut3Region)    => RegistrationErrorPayload("Região NUT3 inválida.")
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
              case Right((token, isAdmin)) => LoginPayload(token.value, isAdmin)
              case Left(VoterNotFound)     => LoginErrorPayload("Eleitor não encontrado.")
              case Left(InvalidPassword)   => LoginErrorPayload("Credenciais inválidas.")
            }
          )
        }
      ),

      Field(
        name      = "createElection",
        fieldType = CreateElectionPayloadType,
        arguments = TitleArg :: StartDateArg :: EndDateArg :: Nil,
        resolve   = ctx => {
          if (ctx.ctx.authenticatedVoter.isEmpty)
            Future.successful(ElectionErrorPayload("Autenticação necessária."))
          else if (!ctx.ctx.authenticatedVoter.exists(_.isAdmin))
            Future.successful(ElectionErrorPayload("Acesso restrito a administradores."))
          else {
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
        }
      ),

      Field(
        name      = "addCandidate",
        fieldType = AddCandidatePayloadType,
        arguments = ElectionIdArg :: NameArg :: PartyArg :: PhotoUrlArg :: NumberArg :: Nil,
        resolve   = ctx => {
          if (ctx.ctx.authenticatedVoter.isEmpty)
            Future.successful(CandidateErrorPayload("Autenticação necessária."))
          else if (!ctx.ctx.authenticatedVoter.exists(_.isAdmin))
            Future.successful(CandidateErrorPayload("Acesso restrito a administradores."))
          else {

          val electionIdStr = ctx.arg(ElectionIdArg)
          val name          = ctx.arg(NameArg)
          val party         = ctx.arg(PartyArg)
          val photoUrl      = ctx.arg(PhotoUrlArg)
          val number        = ctx.arg(NumberArg)

          ctx.ctx.dispatcher.unsafeToFuture(
            IO.fromTry(Try(UUID.fromString(electionIdStr)))
              .flatMap { electionId =>
                ctx.ctx.addCandidateUseCase.execute(electionId, name, party, photoUrl, number).map {
                  case Right(c)                    =>
                    CandidatePayload(c.id.value.toString, c.electionId.value.toString, c.name.value, c.party, c.photoUrl, c.number)
                  case Left(ElectionNotFound)      => CandidateErrorPayload("Eleição não encontrada.")
                  case Left(ElectionAlreadyStarted) => CandidateErrorPayload("A eleição já teve início. Não é possível adicionar candidatos.")
                  case Left(CandidateNameTooShort) => CandidateErrorPayload("O nome do candidato é demasiado curto (mínimo 2 caracteres).")
                }
              }
              .handleError(_ => CandidateErrorPayload("ID de eleição inválido."))
          )
          }
        }
      )
    )
  )
}
