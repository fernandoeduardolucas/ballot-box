package pt.ipp.estg.election.api.graphql

import cats.effect.IO
import pt.ipp.estg.election.api.graphql.schemas.ElectionSchema._
import pt.ipp.estg.election.election.domain.{Election, ElectionScope}
import sangria.schema._

import scala.concurrent.Future
import scala.util.Try
import java.util.UUID

object QueryType {

  private val ElectionIdArg = Argument("electionId", StringType)

  private def toElectionPayload(e: Election): ElectionPayload =
    ElectionPayload(
      e.id.value.toString,
      e.title.value,
      e.startDate.toString,
      e.endDate.toString,
      ElectionScope.regionCode(e.scope),
      ElectionScope.label(e.scope)
    )

  val Query: ObjectType[ElectionContext, Unit] = ObjectType(
    "Query",
    fields[ElectionContext, Unit](

      Field("health", StringType, resolve = _ => "ok"),

      Field(
        name      = "activeElections",
        fieldType = ListType(ElectionPayloadType),
        resolve   = ctx =>
          ctx.ctx.dispatcher.unsafeToFuture(
            ctx.ctx.listActiveElectionsUseCase.execute().map(_.map(toElectionPayload))
          )
      ),

      Field(
        name      = "allElections",
        fieldType = ListType(ElectionPayloadType),
        resolve   = ctx =>
          ctx.ctx.dispatcher.unsafeToFuture(
            ctx.ctx.listAllElectionsUseCase.execute().map(_.map(toElectionPayload))
          )
      ),

      Field(
        name      = "electionCandidates",
        fieldType = ListType(CandidatePayloadType),
        arguments = ElectionIdArg :: Nil,
        resolve   = ctx =>
          ctx.ctx.dispatcher.unsafeToFuture(
            IO.fromTry(Try(UUID.fromString(ctx.arg(ElectionIdArg))))
              .flatMap { uuid =>
                ctx.ctx.listElectionCandidatesUseCase.execute(uuid).map(
                  _.map(c => CandidatePayload(
                    c.id.value.toString, c.electionId.value.toString,
                    c.name.value, c.party, c.photoUrl, c.number
                  ))
                )
              }
              .handleError(_ => List.empty)
          )
      ),

      Field(
        name      = "electionResults",
        fieldType = ListType(VoteCountPayloadType),
        arguments = ElectionIdArg :: Nil,
        resolve   = ctx => {
          if (ctx.ctx.authenticatedVoter.isEmpty)
            Future.failed(new Exception("Autenticação necessária."))
          else if (!ctx.ctx.authenticatedVoter.exists(_.isAdmin))
            Future.failed(new Exception("Acesso restrito a administradores."))
          else
            ctx.ctx.dispatcher.unsafeToFuture(
              IO.fromTry(Try(UUID.fromString(ctx.arg(ElectionIdArg))))
                .flatMap { uuid =>
                  ctx.ctx.getVoteResultsUseCase.execute(uuid).map(
                    _.map(vc => VoteCountPayload(vc.candidateId.value.toString, vc.candidateName.value, vc.count))
                  )
                }
                .handleError(_ => List.empty[VoteCountPayload])
            )
        }
      )
    )
  )
}
