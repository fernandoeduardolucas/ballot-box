package pt.ipp.estg.election.identity.infrastructure

import cats.effect.Sync
import io.circe.parser.parse
import pdi.jwt.{Jwt, JwtAlgorithm}
import pt.ipp.estg.election.identity.application.TokenVerifier
import pt.ipp.estg.election.identity.domain.{AuthenticatedVoter, CivilId, Nut3Region, VoterId}

import java.util.UUID
import scala.util.Try

class JwtTokenVerifier[F[_]: Sync](secret: String) extends TokenVerifier[F] {

  def verify(rawToken: String): F[Option[AuthenticatedVoter]] =
    Sync[F].delay {
      Jwt.decode(rawToken, secret, Seq(JwtAlgorithm.HS256)).toOption
        .flatMap { claim =>
          // jwt-scala v9 extracts standard claims (sub, exp, iat) out of content
          // into JwtClaim fields — read sub from claim.subject, not from content
          parse(claim.content).toOption.flatMap { json =>
            val cursor = json.hcursor
            for {
              sub        <- claim.subject
              civilId    <- cursor.get[String]("civilId").toOption
              regionCode <- cursor.get[String]("nut3Region").toOption
              isAdmin    <- cursor.get[Boolean]("isAdmin").toOption
              uuid       <- Try(UUID.fromString(sub)).toOption
              region     <- Nut3Region.fromCode(regionCode)
            } yield AuthenticatedVoter(VoterId(uuid), CivilId(civilId), region, isAdmin)
          }
        }
    }
}
