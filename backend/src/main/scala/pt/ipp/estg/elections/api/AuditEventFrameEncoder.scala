package pt.ipp.estg.elections.api

import org.http4s.websocket.WebSocketFrame
import pt.ipp.estg.elections.domain.AuditEvent

/** DIP/SRP: contrato de conversão de `AuditEvent` para payload WebSocket. */
trait AuditEventFrameEncoder:
  def encode(event: AuditEvent): WebSocketFrame

/** Implementação padrão em texto simples. */
object PlainTextAuditEventFrameEncoder extends AuditEventFrameEncoder:
  override def encode(event: AuditEvent): WebSocketFrame =
    WebSocketFrame.Text(s"${event.at}|${event.action}|${event.actor}")
