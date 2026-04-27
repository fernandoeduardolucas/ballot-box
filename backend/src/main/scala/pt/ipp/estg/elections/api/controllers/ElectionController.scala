package pt.ipp.estg.elections.api.controllers

import cats.effect.kernel.Async
import cats.syntax.all.*
import fs2.Stream
import io.circe.syntax.*
import io.circe.{Json, JsonObject}
import org.http4s.*
import org.http4s.circe.*
import org.http4s.dsl.Http4sDsl
import org.http4s.server.websocket.WebSocketBuilder2
import org.http4s.websocket.WebSocketFrame
import pt.ipp.estg.elections.api.JsonCodecs
import pt.ipp.estg.elections.api.JsonCodecs.GraphQLRequest
import pt.ipp.estg.elections.domain.*
import pt.ipp.estg.elections.infra.EventBus
import pt.ipp.estg.elections.repository.ElectionRepository
import pt.ipp.estg.elections.services.ElectionServiceAlg
import java.util.UUID

final class ElectionController[F[_]: Async](
  service: ElectionServiceAlg[F],
  repo: ElectionRepository[F],
  bus: EventBus[F]
) extends Http4sDsl[F]:
  import JsonCodecs.given

  given EntityDecoder[F, GraphQLRequest] = jsonOf[F, GraphQLRequest]

  private def auditEventToWebSocketFrame(event: AuditEvent): WebSocketFrame =
    WebSocketFrame.Text(s"${event.at}|${event.action}|${event.actor}")

  private def variableAsString(variables: Option[JsonObject], fieldName: String): Option[String] =
    variables.flatMap(obj => obj(fieldName)).flatMap(json => json.asString)

  private def variableAsUuid(variables: Option[JsonObject], fieldName: String): Either[String, UUID] =
    variableAsString(variables, fieldName)
      .toRight(s"Variável GraphQL obrigatória não enviada: $fieldName")
      .flatMap(value => Either.catchNonFatal(UUID.fromString(value)).left.map(error => error.getMessage))

  private def resolveGraphql(request: GraphQLRequest): F[Json] =
    val queryText = request.query

    if queryText.contains("health") then
      Json.obj("data" -> Json.obj("health" -> Json.obj("status" -> Json.fromString("ok")))).pure[F]
    else if queryText.contains("election") then
      variableAsUuid(request.variables, "id") match
        case Left(errorMessage) =>
          Json.obj("errors" -> Json.arr(Json.obj("message" -> Json.fromString(errorMessage)))).pure[F]
        case Right(electionUuid) =>
          repo.findElection(ElectionId(electionUuid)).map {
            case Some(election) => Json.obj("data" -> Json.obj("election" -> election.asJson))
            case None => Json.obj("errors" -> Json.arr(Json.obj("message" -> Json.fromString("Eleição não encontrada"))))
          }
    else if queryText.contains("registerVoter") then
      val voterIdResult = variableAsString(request.variables, "id").toRight("Variável GraphQL obrigatória não enviada: id")
      val fullNameResult = variableAsString(request.variables, "fullName").toRight("Variável GraphQL obrigatória não enviada: fullName")
      val electionIdResult = variableAsUuid(request.variables, "electionId")
      (voterIdResult, fullNameResult, electionIdResult) match
        case (Right(voterId), Right(fullName), Right(electionUuid)) =>
          val voter = Voter(VoterId(voterId), fullName, Set(ElectionId(electionUuid)), Set.empty)
          service.registerVoter(voter).as(Json.obj("data" -> Json.obj("registerVoter" -> Json.obj("ok" -> Json.True))))
        case _ =>
          val errors = List(voterIdResult.left.toOption, fullNameResult.left.toOption, electionIdResult.left.toOption).flatten
          val errorObjects = errors.map(error => Json.obj("message" -> Json.fromString(error)))
          Json.obj("errors" -> Json.arr(errorObjects*)).pure[F]
    else if queryText.contains("vote") then
      val voterIdResult = variableAsString(request.variables, "voterId").toRight("Variável GraphQL obrigatória não enviada: voterId")
      val electionIdResult = variableAsUuid(request.variables, "electionId")
      val candidateIdResult = variableAsUuid(request.variables, "candidateId")
      (voterIdResult, electionIdResult, candidateIdResult) match
        case (Right(voterId), Right(electionUuid), Right(candidateUuid)) =>
          service.vote(VoterId(voterId), ElectionId(electionUuid), CandidateId(candidateUuid)).map {
            case Right(result) =>
              val accepted = result == ()
              Json.obj("data" -> Json.obj("vote" -> Json.obj("accepted" -> Json.fromBoolean(accepted))))
            case Left(error) =>
              Json.obj("errors" -> Json.arr(Json.obj("message" -> Json.fromString(error.toString))))
          }
        case _ =>
          val errors = List(voterIdResult.left.toOption, electionIdResult.left.toOption, candidateIdResult.left.toOption).flatten
          val errorObjects = errors.map(error => Json.obj("message" -> Json.fromString(error)))
          Json.obj("errors" -> Json.arr(errorObjects*)).pure[F]
    else if queryText.contains("results") then
      variableAsUuid(request.variables, "electionId") match
        case Left(errorMessage) =>
          Json.obj("errors" -> Json.arr(Json.obj("message" -> Json.fromString(errorMessage)))).pure[F]
        case Right(electionUuid) =>
          service.results(ElectionId(electionUuid)).map { counts =>
            val resultsJson = counts.map((candidateId, totalVotes) => candidateId.value.toString -> Json.fromInt(totalVotes))
            Json.obj("data" -> Json.obj("results" -> Json.obj(resultsJson.toSeq*)))
          }
    else
      Json.obj("errors" -> Json.arr(Json.obj("message" -> Json.fromString("Operação GraphQL não suportada")))).pure[F]

  def routes(ws: WebSocketBuilder2[F]): HttpRoutes[F] = HttpRoutes.of[F] {
    case request @ POST -> Root / "graphql" =>
      request.as[GraphQLRequest].flatMap(resolveGraphql).flatMap(response => Ok(response))

    case GET -> Root / "audit" / "stream" =>
      val out: Stream[F, WebSocketFrame] = bus.stream.map(event => auditEventToWebSocketFrame(event))
      ws.build(out, incoming => incoming.drain)
  }
