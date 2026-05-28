package pt.ipp.estg.election.aop

import cats.effect.IO
import cats.syntax.all.*
import munit.CatsEffectSuite
import org.http4s.*
import org.http4s.dsl.io.*
import org.http4s.implicits.*
import org.typelevel.ci.CIString

class DefensiveRateLimitMiddlewareSuite extends CatsEffectSuite:

  private val routes = HttpRoutes.of[IO] {
    case POST -> Root / "graphql" => Ok("ok")
    case GET -> Root / "graphql"  => Ok("ok")
  }

  private def extractIp(req: Request[IO]): String =
    req.headers
      .get(CIString("X-Forwarded-For"))
      .map(_.head.value)
      .getOrElse("unknown")

  private def extractBearerToken(req: Request[IO]): Option[String] =
    req.headers
      .get(CIString("Authorization"))
      .map(_.head.value)
      .filter(_.startsWith("Bearer "))
      .map(_.drop(7).trim)

  test("devolve 429 no quarto POST /graphql do mesmo IP dentro da janela"):
    val request = Request[IO](
      method = Method.POST,
      uri = uri"/graphql",
      headers = Headers(Header.Raw(CIString("X-Forwarded-For"), "203.0.113.10"))
    )

    for
      middleware <- DefensiveRateLimitMiddleware.forGraphql[IO]("graphql", extractIp, extractBearerToken)
      app = middleware(routes.orNotFound)
      statuses <- List.fill(4)(app.run(request).map(_.status)).sequence
    yield assertEquals(statuses, List(Status.Ok, Status.Ok, Status.Ok, Status.TooManyRequests))

  test("aplica o limite tambem ao token mesmo quando o IP muda"):
    def request(ip: String): Request[IO] =
      Request[IO](
        method = Method.POST,
        uri = uri"/graphql",
        headers = Headers(
          Header.Raw(CIString("X-Forwarded-For"), ip),
          Header.Raw(CIString("Authorization"), "Bearer voter-token")
        )
      )

    for
      middleware <- DefensiveRateLimitMiddleware.forGraphql[IO]("graphql", extractIp, extractBearerToken)
      app = middleware(routes.orNotFound)
      statuses <- List("203.0.113.1", "203.0.113.2", "203.0.113.3", "203.0.113.4")
        .traverse(ip => app.run(request(ip)).map(_.status))
    yield assertEquals(statuses, List(Status.Ok, Status.Ok, Status.Ok, Status.TooManyRequests))

  test("nao limita outras rotas ou metodos"):
    val request = Request[IO](
      method = Method.GET,
      uri = uri"/graphql",
      headers = Headers(Header.Raw(CIString("X-Forwarded-For"), "203.0.113.20"))
    )

    for
      middleware <- DefensiveRateLimitMiddleware.forGraphql[IO]("graphql", extractIp, extractBearerToken)
      app = middleware(routes.orNotFound)
      statuses <- List.fill(5)(app.run(request).map(_.status)).sequence
    yield assertEquals(statuses, List.fill(5)(Status.Ok))
