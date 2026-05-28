package pt.ipp.estg.election.aop

import io.circe.{Encoder, Json}

case class AuditEvent(
  eventType: String,
  civilId:   Option[String],
  ip:        String,
  success:   Boolean,
  reason:    Option[String]
)

object AuditEvent {
  given Encoder[AuditEvent] = Encoder.instance { event =>
    Json.obj(
      "eventType" -> Json.fromString(event.eventType),
      "civilId"   -> event.civilId.fold(Json.Null)(Json.fromString),
      "ip"        -> Json.fromString(event.ip),
      "success"   -> Json.fromBoolean(event.success),
      "reason"    -> event.reason.fold(Json.Null)(Json.fromString)
    )
  }
}
