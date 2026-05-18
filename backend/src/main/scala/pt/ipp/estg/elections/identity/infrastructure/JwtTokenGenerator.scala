package pt.ipp.estg.election.identity.infrastructure

import cats.effect.Sync
import io.circe.Json
import io.circe.syntax._
import pdi.jwt.{Jwt, JwtAlgorithm, JwtClaim}
import pt.ipp.estg.election.identity.application.TokenGenerator
import pt.ipp.estg.election.identity.domain.{AuthToken, Voter}

import java.time.Instant

class JwtTokenGenerator[F[_]: Sync](secret: String, expirationSeconds: Long) extends TokenGenerator[F] {

  def generate(voter: Voter): F[AuthToken] =
    Sync[F].delay {
      val now = Instant.now()
      val payload = Json.obj(
        "sub"        -> voter.id.value.toString.asJson,
        "civilId"    -> voter.civilId.value.asJson,
        "nut3Region" -> voter.nut3Region.code.asJson,
        "isAdmin"    -> voter.isAdmin.asJson
      ).noSpaces

      val claim = JwtClaim(
        content    = payload,
        expiration = Some(now.plusSeconds(expirationSeconds).getEpochSecond),
        issuedAt   = Some(now.getEpochSecond)
      )
      AuthToken(Jwt.encode(claim, secret, JwtAlgorithm.HS256))
    }
}
