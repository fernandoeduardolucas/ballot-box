package pt.ipp.estg.election.identity.domain

enum Nut3Region(val code: String, val label: String):
  case AltoMinho               extends Nut3Region("alto-minho",                "Alto Minho")
  case Cavado                  extends Nut3Region("cavado",                    "Cávado")
  case Ave                     extends Nut3Region("ave",                       "Ave")
  case AreaMetropolitanaPorto  extends Nut3Region("am-porto",                  "Área Metropolitana do Porto")
  case AltoTamega              extends Nut3Region("alto-tamega",               "Alto Tâmega")
  case TamegaESousa            extends Nut3Region("tamega-e-sousa",            "Tâmega e Sousa")
  case Douro                   extends Nut3Region("douro",                     "Douro")
  case TerrasDeTrasOsMontes    extends Nut3Region("terras-tras-os-montes",     "Terras de Trás-os-Montes")
  case Oeste                   extends Nut3Region("oeste",                     "Oeste")
  case RegiaoDeAveiro          extends Nut3Region("regiao-aveiro",             "Região de Aveiro")
  case RegiaoDeCoimbra         extends Nut3Region("regiao-coimbra",            "Região de Coimbra")
  case RegiaoDeLeiria          extends Nut3Region("regiao-leiria",             "Região de Leiria")
  case ViseuDaoLafoes          extends Nut3Region("viseu-dao-lafoes",          "Viseu Dão Lafões")
  case BeiraBaixa              extends Nut3Region("beira-baixa",               "Beira Baixa")
  case MedioTejo               extends Nut3Region("medio-tejo",                "Médio Tejo")
  case BeirasSerra             extends Nut3Region("beiras-serra",              "Beiras e Serra da Estrela")
  case AreaMetropolitanaLisboa extends Nut3Region("am-lisboa",                 "Área Metropolitana de Lisboa")
  case AlentejaoLitoral        extends Nut3Region("alentejo-litoral",          "Alentejo Litoral")
  case BaixoAlentejo           extends Nut3Region("baixo-alentejo",            "Baixo Alentejo")
  case LeziradoTejo            extends Nut3Region("lezira-do-tejo",            "Lezíria do Tejo")
  case AltoAlentejo            extends Nut3Region("alto-alentejo",             "Alto Alentejo")
  case AlentejoCentral         extends Nut3Region("alentejo-central",          "Alentejo Central")
  case Algarve                 extends Nut3Region("algarve",                   "Algarve")
  case Acores                  extends Nut3Region("acores",                    "Região Autónoma dos Açores")
  case Madeira                 extends Nut3Region("madeira",                   "Região Autónoma da Madeira")

object Nut3Region:
  def fromCode(code: String): Option[Nut3Region] =
    Nut3Region.values.find(_.code == code)
