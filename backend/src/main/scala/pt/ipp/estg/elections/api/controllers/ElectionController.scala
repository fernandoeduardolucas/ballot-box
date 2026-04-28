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
import pt.ipp.estg.elections.api.AuditEventFrameEncoder
import pt.ipp.estg.elections.api.JsonCodecs
import pt.ipp.estg.elections.api.JsonCodecs.GraphQLRequest
import pt.ipp.estg.elections.application.ports.in.ElectionUseCases
import pt.ipp.estg.elections.domain.*
import pt.ipp.estg.elections.infra.EventBus
import java.util.UUID

/** Controlador HTTP/WebSocket com endpoint GraphQL textual simplificado. */
final class ElectionController[F[_]: Async](
  useCases: ElectionUseCases[F],
  bus: EventBus[F],
  frameEncoder: AuditEventFrameEncoder,
  graphqlPath: String,
  auditStreamPath: String
) extends Http4sDsl[F]:
  import JsonCodecs.given

  given EntityDecoder[F, GraphQLRequest] = jsonOf[F, GraphQLRequest]

  /** Converte eventos de auditoria para frames WS via estratégia injetada. */
  private def auditEventToWebSocketFrame(event: AuditEvent): WebSocketFrame =
    frameEncoder.encode(event)

  /** Lê variável textual opcional do objeto `variables` da request GraphQL. */
  private def variableAsString(variables: Option[JsonObject], fieldName: String): Option[String] =
    variables.flatMap(obj => obj(fieldName)).flatMap(json => json.asString)

  /** Lê e valida variável UUID obrigatória, retornando erro legível para cliente. */
  private def variableAsUuid(variables: Option[JsonObject], fieldName: String): Either[String, UUID] =
    variableAsString(variables, fieldName)
      .toRight(s"Variável GraphQL obrigatória não enviada: $fieldName")
      .flatMap(value => Either.catchNonFatal(UUID.fromString(value)).left.map(error => error.getMessage))

  /** Resolve operações GraphQL por inspeção textual do campo `query`. */
  private def resolveGraphql(request: GraphQLRequest): F[Json] =
    val queryText = request.query

    val operationHandlers = List(
      "health" -> handleHealth _,
      "election" -> handleElection _,
      "registerVoter" -> handleRegisterVoter _,
      "vote" -> handleVote _,
      "results" -> handleResults _
    )

    operationHandlers.find { case (operationName, _) => queryText.contains(operationName) } match
      case Some((_, operationHandler)) => operationHandler(request)
      case None => Json.obj("errors" -> Json.arr(Json.obj("message" -> Json.fromString("Operação GraphQL não suportada")))).pure[F]

  private def handleHealth(request: GraphQLRequest): F[Json] =
    Json.obj("data" -> Json.obj("health" -> Json.obj("status" -> Json.fromString("ok")))).pure[F]

  private def handleElection(request: GraphQLRequest): F[Json] =
    variableAsUuid(request.variables, "id") match
      case Left(errorMessage) =>
        Json.obj("errors" -> Json.arr(Json.obj("message" -> Json.fromString(errorMessage)))).pure[F]
      case Right(electionUuid) =>
        useCases.findElection(ElectionId(electionUuid)).map {
          case Some(election) => Json.obj("data" -> Json.obj("election" -> election.asJson))
          case None => Json.obj("errors" -> Json.arr(Json.obj("message" -> Json.fromString("Eleição não encontrada"))))
        }

  private def handleRegisterVoter(request: GraphQLRequest): F[Json] =
    val voterIdResult = variableAsString(request.variables, "id").toRight("Variável GraphQL obrigatória não enviada: id")
    val fullNameResult = variableAsString(request.variables, "fullName").toRight("Variável GraphQL obrigatória não enviada: fullName")
    val electionIdResult = variableAsUuid(request.variables, "electionId")
    (voterIdResult, fullNameResult, electionIdResult) match
      case (Right(voterId), Right(fullName), Right(electionUuid)) =>
        val voter = Voter(VoterId(voterId), fullName, Set(ElectionId(electionUuid)), Set.empty)
        useCases.registerVoter(voter).as(Json.obj("data" -> Json.obj("registerVoter" -> Json.obj("ok" -> Json.True))))
      case (voterIdOutcome, fullNameOutcome, electionIdOutcome) =>
        val errors = List(voterIdOutcome.left.toOption, fullNameOutcome.left.toOption, electionIdOutcome.left.toOption).flatten
        val errorObjects = errors.map(error => Json.obj("message" -> Json.fromString(error)))
        Json.obj("errors" -> Json.arr(errorObjects*)).pure[F]

  private def handleVote(request: GraphQLRequest): F[Json] =
    val voterIdResult = variableAsString(request.variables, "voterId").toRight("Variável GraphQL obrigatória não enviada: voterId")
    val electionIdResult = variableAsUuid(request.variables, "electionId")
    val candidateIdResult = variableAsUuid(request.variables, "candidateId")
    (voterIdResult, electionIdResult, candidateIdResult) match
      case (Right(voterId), Right(electionUuid), Right(candidateUuid)) =>
        useCases.vote(VoterId(voterId), ElectionId(electionUuid), CandidateId(candidateUuid)).map {
          case Right(result) =>
            val accepted = result == ()
            Json.obj("data" -> Json.obj("vote" -> Json.obj("accepted" -> Json.fromBoolean(accepted))))
          case Left(error) =>
            Json.obj("errors" -> Json.arr(Json.obj("message" -> Json.fromString(error.toString))))
        }
      case (voterIdOutcome, electionIdOutcome, candidateIdOutcome) =>
        val errors = List(voterIdOutcome.left.toOption, electionIdOutcome.left.toOption, candidateIdOutcome.left.toOption).flatten
        val errorObjects = errors.map(error => Json.obj("message" -> Json.fromString(error)))
        Json.obj("errors" -> Json.arr(errorObjects*)).pure[F]

  private def handleResults(request: GraphQLRequest): F[Json] =
    variableAsUuid(request.variables, "electionId") match
      case Left(errorMessage) =>
        Json.obj("errors" -> Json.arr(Json.obj("message" -> Json.fromString(errorMessage)))).pure[F]
      case Right(electionUuid) =>
        useCases.results(ElectionId(electionUuid)).map { counts =>
          val resultsJson = counts.map((candidateId, totalVotes) => candidateId.value.toString -> Json.fromInt(totalVotes))
          Json.obj("data" -> Json.obj("results" -> Json.obj(resultsJson.toSeq*)))
        }

  def routes(ws: WebSocketBuilder2[F]): HttpRoutes[F] = HttpRoutes.of[F] {
    // Endpoint GraphQL configurável.
    case request if request.method == Method.POST && request.uri.path.renderString == graphqlPath =>
      request.as[GraphQLRequest].flatMap(resolveGraphql).flatMap(response => Ok(response))

    // Stream de auditoria em tempo real configurável.
    case request if request.method == Method.GET && request.uri.path.renderString == auditStreamPath =>
      val out: Stream[F, WebSocketFrame] = bus.stream.map(event => auditEventToWebSocketFrame(event))
      ws.build(out, incoming => incoming.drain)
  }
