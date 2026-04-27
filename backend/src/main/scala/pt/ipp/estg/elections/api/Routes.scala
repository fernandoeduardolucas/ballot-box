package pt.ipp.estg.elections.api

import cats.effect.kernel.Async
import cats.syntax.all.*
import fs2.Stream
import io.circe.syntax.*
import org.http4s.*
import org.http4s.circe.*
import org.http4s.dsl.Http4sDsl
import org.http4s.server.websocket.WebSocketBuilder2
import org.http4s.websocket.WebSocketFrame
import pt.ipp.estg.elections.domain.*
import pt.ipp.estg.elections.infra.EventBus
import java.util.UUID

final class Routes[F[_]: Async](service: ElectionServiceAlg[F], repo: ElectionRepository[F], bus: EventBus[F]) extends Http4sDsl[F]:
  import JsonCodecs.given
  import JsonCodecs.*

  given EntityDecoder[F, RegisterVoterRequest] = jsonOf[F, RegisterVoterRequest]
  given EntityDecoder[F, VoteRequest] = jsonOf[F, VoteRequest]

  def http(ws: WebSocketBuilder2[F]): HttpRoutes[F] = HttpRoutes.of[F] {
    case GET -> Root / "health" => Ok(Map("status" -> "ok").asJson)

    case GET -> Root / "elections" / id =>
      repo.findElection(ElectionId(UUID.fromString(id))).flatMap {
        case Some(e) => Ok(e.asJson)
        case None => NotFound(Map("error" -> "Eleição não encontrada").asJson)
      }

    case req @ POST -> Root / "voters" =>
      req.as[RegisterVoterRequest].flatMap { r =>
        service.registerVoter(Voter(VoterId(r.id), r.fullName, Set(ElectionId(r.electionId)), Set.empty)) *> Created()
      }

    case req @ POST -> Root / "votes" =>
      req.as[VoteRequest].flatMap { r =>
        service.vote(VoterId(r.voterId), ElectionId(r.electionId), CandidateId(r.candidateId)).flatMap {
          case Right(_) => Created(Map("message" -> "Voto registado com sucesso").asJson)
          case Left(e) => BadRequest(Map("error" -> e.toString).asJson)
        }
      }

    case GET -> Root / "results" / id =>
      service.results(ElectionId(UUID.fromString(id))).flatMap { counts =>
        Ok(counts.map((cid, n) => cid.value.toString -> n).asJson)
      }

    case GET -> Root / "audit" / "stream" =>
      val out: Stream[F, WebSocketFrame] = bus.stream.map(e => WebSocketFrame.Text(s"${e.at}|${e.action}|${e.actor}"))
      ws.build(out, _.drain)
  }
