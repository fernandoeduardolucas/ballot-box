package pt.ipp.estg.election.aop

import cats.effect.{Ref, Temporal}
import cats.syntax.all.*
import org.http4s.{Header, Headers, HttpApp, Method, Request, Response, Status}
import org.typelevel.ci.CIString

import scala.concurrent.duration.*

object DefensiveRateLimitMiddleware:

  final case class Config(
      maxRequests: Int = 3,
      window: FiniteDuration = 2.seconds
  )

  def forGraphql[F[_]: Temporal](
      graphqlPath: String,
      extractIp: Request[F] => String,
      extractToken: Request[F] => Option[String],
      config: Config = Config()
  ): F[HttpApp[F] => HttpApp[F]] =
    Ref.of[F, Map[String, Vector[FiniteDuration]]](Map.empty).map { requestsByKey =>
      val protectedPath = normalizePath(graphqlPath)

      app =>
        HttpApp[F] { req =>
          if req.method == Method.POST && req.uri.path.renderString == protectedPath then
            val keys = requestKeys(req, extractIp, extractToken)
            Temporal[F].realTime.flatMap { now =>
              requestsByKey.modify { previous =>
                val cutoff = now - config.window
                val pruned = previous.iterator
                  .map { case (key, timestamps) => key -> timestamps.filter(_ > cutoff) }
                  .filter { case (_, timestamps) => timestamps.nonEmpty }
                  .toMap
                val updated = keys
                  .map { key => key -> (pruned.getOrElse(key, Vector.empty) :+ now) }
                  .toMap
                val blocked = updated.values.exists(_.size > config.maxRequests)

                (pruned ++ updated, blocked)
              }.flatMap {
                case true  => tooManyRequests[F](config).pure[F]
                case false => app.run(req)
              }
            }
          else app.run(req)
        }
    }

  private def normalizePath(path: String): String =
    val clean = path.trim
    if clean.startsWith("/") then clean else s"/$clean"

  private def tooManyRequests[F[_]](config: Config): Response[F] =
    val retryAfterSeconds = config.window.toSeconds.max(1L).toString
    Response[F](
      status = Status.TooManyRequests,
      headers = Headers(Header.Raw(CIString("Retry-After"), retryAfterSeconds))
    )

  private def requestKeys[F[_]](
      req: Request[F],
      extractIp: Request[F] => String,
      extractToken: Request[F] => Option[String]
  ): List[String] =
    val ip = extractIp(req).trim match
      case ""    => "unknown"
      case value => value

    s"ip:$ip" :: extractToken(req).map(_.trim).filter(_.nonEmpty).map(token => s"token:$token").toList
