ThisBuild / scalaVersion := "3.6.4"
ThisBuild / organization := "pt.ipp.estg"
ThisBuild / version := "0.1.0-SNAPSHOT"

lazy val root = (project in file("."))
  .settings(
    name := "sistema-eleitoral-backend",
    Compile / run / fork := true,
    libraryDependencies ++= Seq(
      "org.typelevel" %% "cats-effect" % "3.5.7",
      "org.typelevel" %% "cats-core" % "2.10.0",
      "org.http4s" %% "http4s-ember-server" % "0.23.34",
      "org.http4s" %% "http4s-dsl" % "0.23.34",
      "org.http4s" %% "http4s-circe" % "0.23.34",
      "io.circe" %% "circe-core" % "0.14.10",
      "io.circe" %% "circe-generic" % "0.14.10",
      "io.circe" %% "circe-parser" % "0.14.10",
      "org.tpolecat" %% "doobie-core" % "1.0.0-RC8",
      "org.tpolecat" %% "doobie-postgres" % "1.0.0-RC8",
      "org.mindrot"   % "jbcrypt"         % "0.4",
      "ch.qos.logback" % "logback-classic" % "1.5.18",
      "org.typelevel" %% "log4cats-slf4j" % "2.7.0",
      "org.sangria-graphql" %% "sangria" % "3.4.1",
      "org.sangria-graphql" %% "sangria-circe" % "1.3.2",
      "com.github.pureconfig" %% "pureconfig-core" % "0.17.4",
      "org.scalameta" %% "munit" % "1.1.0" % Test,
      "org.typelevel" %% "munit-cats-effect" % "2.0.0" % Test
    ),
    scalacOptions ++= Seq("-deprecation", "-feature", "-unchecked")
  )
