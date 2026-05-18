package pt.ipp.estg.election.aop

case class AuditEvent(
  eventType: String,
  civilId:   Option[String],
  ip:        String,
  success:   Boolean,
  reason:    Option[String]
)
