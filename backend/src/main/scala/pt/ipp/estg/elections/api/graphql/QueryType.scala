package pt.ipp.estg.election.api.graphql

import cats.effect.IO
import pt.ipp.estg.election.api.graphql.schemas.ElectionSchema._
import sangria.schema._

import scala.util.Try
import java.util.UUID

object QueryType {

  private val ElectionIdArg = Argument("electionId", StringType)

  val Query: ObjectType[ElectionContext, Unit] = ObjectType(
    "Query",
    fields[ElectionContext, Unit](

      Field("health", StringType, resolve = _ => "ok"),

      Field(
        name      = "activeElections",
        fieldType = ListType(ElectionPayloadType),
        resolve   = ctx =>
          ctx.ctx.dispatcher.unsafeToFuture(
            ctx.ctx.listActiveElectionsUseCase.execute().map(
              _.map(e => ElectionPayload(e.id.value.toString, e.title.value, e.startDate.toString, e.endDate.toString))
            )
          )
      ),

      Field(
        name      = "allElections",
        fieldType = ListType(ElectionPayloadType),
        resolve   = ctx =>
          ctx.ctx.dispatcher.unsafeToFuture(
            ctx.ctx.listAllElectionsUseCase.execute().map(
              _.map(e => ElectionPayload(e.id.value.toString, e.title.value, e.startDate.toString, e.endDate.toString))
            )
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
      )
    )
  )
}
